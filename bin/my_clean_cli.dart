
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:archive/archive.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Custom HTTP client that can bypass SSL verification when needed
class CustomHttpClient {
  static http.Client createClient({bool insecure = false}) {
    if (insecure) {
      // Create a custom HTTP client that bypasses SSL verification
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return IOClient(httpClient);
    }
    return http.Client();
  }
}

/// The main function of the CLI tool.
/// It parses the command-line arguments and calls the appropriate functions.
/// The CLI tool supports two commands: create and update-pubspec.
/// The create command downloads a template ZIP file from GitHub and extracts the contents.
/// The update-pubspec command adds predefined dependencies and assets to the pubspec.yaml file.
/// The predefined dependencies are defined in the function.
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('create', abbr: 'c', help: 'Create predefined folders and files')
    ..addFlag('update-pubspec', abbr: 'u', help: 'Update pubspec.yaml')
    ..addOption('repo', help: 'Custom repository ZIP URL (e.g., https://github.com/user/repo/archive/refs/heads/master.zip)')
    ..addFlag('insecure', help: 'Skip SSL certificate verification (use with caution)')
    // Core module flags
    ..addFlag('theme', help: 'Add theme module from template')
    ..addFlag('network', help: 'Add network module from template')
    ..addFlag('storage', help: 'Add storage module from template')
    ..addFlag('router', help: 'Add router module from template')
    ..addFlag('di', help: 'Add dependency injection module from template')
    ..addFlag('constants', help: 'Add constants module from template')
    ..addFlag('utils', help: 'Add utils module from template')
    ..addFlag('widgets', help: 'Add widgets module from template')
    ..addFlag('localization', help: 'Add localization module from template')
    ..addFlag('config', help: 'Add config module from template')
    ..addFlag('core-all', help: 'Add all core modules from template')
    // Feature flags
    ..addOption('feature', help: 'Add a new feature from template (e.g., --feature=user)')
    ..addFlag('update-deps', help: 'Update dependencies with clean architecture stack');

  try {
    final argResults = parser.parse(arguments);

    // Handle update dependencies first
    if (argResults['update-deps'] == true) {
      updateDependencies();
    }

    // Handle update pubspec
    if (argResults['update-pubspec'] == true) {
      updatePubspec();
    }

    // Handle core modules from template
    if (argResults['core-all'] == true) {
      generateCoreFromTemplate(repoUrl: argResults['repo'] as String?, insecure: argResults['insecure'] as bool? ?? false);
    } else {
      // Handle individual core modules from template
      final repoUrl = argResults['repo'] as String?;
      final insecure = argResults['insecure'] as bool? ?? false;
      
      if (argResults['theme'] == true) generateModuleFromTemplate('theme', repoUrl: repoUrl, insecure: insecure);
      if (argResults['network'] == true) generateModuleFromTemplate('network', repoUrl: repoUrl, insecure: insecure);
      if (argResults['storage'] == true) generateModuleFromTemplate('storage', repoUrl: repoUrl, insecure: insecure);
      if (argResults['router'] == true) generateModuleFromTemplate('router', repoUrl: repoUrl, insecure: insecure);
      if (argResults['di'] == true) generateModuleFromTemplate('di', repoUrl: repoUrl, insecure: insecure);
      if (argResults['constants'] == true) generateModuleFromTemplate('constants', repoUrl: repoUrl, insecure: insecure);
      if (argResults['utils'] == true) generateModuleFromTemplate('utils', repoUrl: repoUrl, insecure: insecure);
      if (argResults['widgets'] == true) generateModuleFromTemplate('widgets', repoUrl: repoUrl, insecure: insecure);
      if (argResults['localization'] == true) generateModuleFromTemplate('localization', repoUrl: repoUrl, insecure: insecure);
      if (argResults['config'] == true) generateModuleFromTemplate('config', repoUrl: repoUrl, insecure: insecure);
    }

    // Handle feature creation from template
    final featureName = argResults['feature'] as String?;
    if (featureName != null && featureName.isNotEmpty) {
      generateFeatureFromTemplate(featureName, repoUrl: argResults['repo'] as String?, insecure: argResults['insecure'] as bool? ?? false);
    }

    // Handle create (legacy functionality)
    if (argResults['create'] == true) {
      final repoUrl = argResults['repo'] as String?;
      final insecure = argResults['insecure'] as bool? ?? false;
      createFoldersAndFiles(repoUrl: repoUrl, insecure: insecure);
    }
  } catch (e) {
    print('Error: $e');
    print('Usage: dart run my_clean_cli [options]');
    print(parser.usage);
  }
}
/// createAsset function is used to create the assets folder in the root directory of the project
void createAsset() {
  // Define the root-level folders to be created
  const folders = [
    'assets/icons/',
    'assets/images/',
    'assets/gifs/',
  ];

  // Create each folder if it doesn't exist
  for (var folder in folders) {
    final dir = Directory(folder);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('Created folder: ${dir.path}');
    } else {
      print('Folder already exists: ${dir.path}');
    }
  }
}

/// createFoldersAndFiles function is used to create the predefined folders and files in the project
/// by downloading a template ZIP file from GitHub and extracting the contents.
/// The template contains the predefined folder structure and some files.
Future<void> createFoldersAndFiles({String? repoUrl, bool insecure = false}) async {
  final targetDir = Directory('lib/');
  createAsset();

  try {
    // Use provided repo URL or fallback to default
    final url = repoUrl ?? 'https://github.com/farooq958/cli_template/archive/refs/heads/master.zip';
    print('Downloading template from: $url');
    
    // Create HTTP client with or without SSL verification
    final httpClient = CustomHttpClient.createClient(insecure: insecure);
    if (insecure) {
      print('Warning: SSL certificate verification is disabled for this request');
    }
    
    final response = await httpClient.get(Uri.parse(url));
    httpClient.close();
    
    if (response.statusCode != 200) {
      throw Exception('Failed to download template: HTTP ${response.statusCode}');
    }
    
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);

    // Extract repository name from URL and determine template prefix
    final repoName = _extractRepoNameFromUrl(url);
    final templatePrefix = '$repoName/lib/';

    print('Using template prefix: $templatePrefix');

    bool foundFiles = false;
    for (final file in archive) {
      if (file.name.startsWith(templatePrefix)) {
        foundFiles = true;
        final relativePath = file.name.substring(templatePrefix.length);
        final filePath = path.join(targetDir.path, relativePath);

        if (file.isFile) {
          final outputFile = File(filePath);
          outputFile.createSync(recursive: true);
          outputFile.writeAsBytesSync(file.content as List<int>);
          print('Created file: $filePath');
        } else if (file is Directory) {
          final outputDir = Directory(filePath);
          outputDir.createSync(recursive: true);
          print('Created directory: $filePath');
        }
      }
    }
    
    if (!foundFiles) {
      print('Warning: No files found with template prefix "$templatePrefix"');
      print('Available files in archive:');
      for (final file in archive) {
        print('  ${file.name}');
      }
    }
  } catch (e) {
    print('Error while creating files: $e');
    if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
      print('This appears to be an SSL certificate issue. For private GitLab instances:');
      print('1. Ensure the repository is publicly accessible');
      print('2. Check if SSL certificates are properly configured');
      print('3. Consider using a different download method or public repository');
    }
  }
}

/// Extract repository name from GitHub or GitLab URL
/// GitHub Example: https://github.com/farooq958/cli_template/archive/refs/heads/master.zip
/// Returns: cli_template-master
/// GitLab Example: https://git.teknosys.ai/fikrfree/fikrfreeapp/-/archive/main/fikrfreeapp-main.zip
/// Returns: fikrfreeapp-main
String _extractRepoNameFromUrl(String url) {
  final uri = Uri.parse(url);
  final pathSegments = uri.pathSegments;
  
  // Check if it's a GitLab URL pattern: .../repo/-/archive/{branch}/{repo}-{branch}.zip
  if (pathSegments.contains('-') && pathSegments.contains('archive')) {
    for (int i = 0; i < pathSegments.length - 3; i++) {
      if (pathSegments[i] == '-' && pathSegments[i + 1] == 'archive') {
        // GitLab pattern: repo/-/archive/branch/repo-branch.zip
        final repoName = pathSegments[i - 1]; // repository name before '-'
        final branchName = pathSegments[i + 2]; // branch name after 'archive'
        return '$repoName-$branchName';
      }
    }
  }
  
  // Check if it's a GitHub URL pattern: .../repo/archive/refs/heads/{branch}.zip
  for (int i = 0; i < pathSegments.length - 1; i++) {
    if (pathSegments[i] == 'archive' && i > 0 && i + 3 < pathSegments.length) {
      final repoName = pathSegments[i - 1];
      // Check if we have the expected pattern: archive/refs/heads/{branch}.zip
      if (pathSegments[i + 1] == 'refs' && pathSegments[i + 2] == 'heads') {
        final branchName = pathSegments[i + 3].replaceAll('.zip', '');
        return '$repoName-$branchName';
      }
    }
  }
  
  // Fallback: try to extract repo name and branch from URL pattern
  // This handles cases where URL structure might be different
  final regex = RegExp(r'/([^/]+)/archive/.*?/([^/]+)\.zip$');
  final match = regex.firstMatch(url);
  if (match != null) {
    final repoName = match.group(1)!;
    final branchName = match.group(2)!;
    return '$repoName-$branchName';
  }
  
  // Ultimate fallback: try to get just repo name and default to master
  final repoRegex = RegExp(r'/([^/]+)/archive/.*?\.zip$');
  final repoMatch = repoRegex.firstMatch(url);
  if (repoMatch != null) {
    final repoName = repoMatch.group(1)!;
    return '$repoName-master';
  }
  
  return 'cli_template-master';
}

/// Update dependencies with clean architecture stack
void updateDependencies() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('pubspec.yaml not found!');
    return;
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final yamlEditor = YamlEditor(pubspecContent);

  final pubspecMap = loadYaml(pubspecContent) as Map;

  // Define clean architecture dependencies
  const cleanArchDependencies = {
    'flutter_bloc': '^9.1.1',
    'dio': '^5.9.0',
    'equatable': '^2.0.8',
    'freezed_annotation': '^3.1.0',
    'go_router': '^17.0.1',
    'shared_preferences': '^2.5.4',
    'encrypt': '^5.0.3',
    'get_it': '^9.2.0',
    'shimmer': '^3.0.0',
    'logger': '^2.6.2',
    'drift': '^2.30.0',
    'sqlite3_flutter_libs': '^0.5.41',
    'path_provider': '^2.1.5',
    'path': '^1.9.1',
    'connectivity_plus': '^7.0.0',
    'cached_network_image': '^3.4.1',
    'flutter_svg': '^2.2.3',
    'flutter_logs': '^2.2.1',
    'cupertino_icons': '^1.0.8',
    'intl': 'any',
  };

  // Define Flutter SDK dependencies
  const flutterSdkDependencies = {
    'flutter_localizations': 'sdk: flutter',
  };

  // Define dev dependencies
  const cleanArchDevDependencies = {
    'build_runner': '^2.10.4',
    'freezed': '^3.2.4',
    'drift_dev': '^2.30.0',
    'mockito': '^5.6.1',
    'flutter_lints': '^6.0.0',
  };

  // Update dependencies
  if (pubspecMap.containsKey('dependencies')) {
    cleanArchDependencies.forEach((package, version) {
      if (!pubspecMap['dependencies'].containsKey(package)) {
        yamlEditor.update(['dependencies', package], version);
        print('Added $package:$version to dependencies.');
      } else {
        print('$package is already in dependencies.');
      }
    });
    
    // Add Flutter SDK dependencies
    flutterSdkDependencies.forEach((package, version) {
      if (!pubspecMap['dependencies'].containsKey(package)) {
        yamlEditor.update(['dependencies', package], version);
        print('Added $package:$version to dependencies.');
      } else {
        print('$package is already in dependencies.');
      }
    });
  } else {
    final allDependencies = Map<String, String>.from(cleanArchDependencies);
    allDependencies.addAll(flutterSdkDependencies);
    yamlEditor.update(['dependencies'], allDependencies);
    print('Added clean architecture dependencies to pubspec.yaml.');
  }

  // Update dev dependencies
  if (pubspecMap.containsKey('dev_dependencies')) {
    cleanArchDevDependencies.forEach((package, version) {
      if (!pubspecMap['dev_dependencies'].containsKey(package)) {
        yamlEditor.update(['dev_dependencies', package], version);
        print('Added $package:$version to dev_dependencies.');
      } else {
        print('$package is already in dev_dependencies.');
      }
    });
  } else {
    yamlEditor.update(['dev_dependencies'], cleanArchDevDependencies);
    print('Added clean architecture dev dependencies to pubspec.yaml.');
  }

  // Update flutter section
  _updateFlutterSection(yamlEditor, pubspecMap);

  // Write the updated content back to the file
  pubspecFile.writeAsStringSync(yamlEditor.toString());
  print('Dependencies updated successfully with clean architecture stack.');
}

/// updatePubspec function is used to add predefined dependencies and assets to the pubspec.yaml file
/// if they don't already exist.
/// It also creates the flutter section if it doesn't exist.
/// The predefined dependencies are defined in the function.
void updatePubspec() {
  // For backward compatibility, just call updateDependencies
  updateDependencies();
}

/// Generate core modules from template
Future<void> generateCoreFromTemplate({String? repoUrl, bool insecure = false}) async {
  try {
    final url = repoUrl ?? 'https://github.com/farooq958/cli_template/archive/refs/heads/master.zip';
    print('Downloading template from: $url');
    
    // Create HTTP client
    final httpClient = CustomHttpClient.createClient(insecure: insecure);
    if (insecure) {
      print('Warning: SSL certificate verification is disabled for this request');
    }
    final response = await httpClient.get(Uri.parse(url));
    httpClient.close();
    
    if (response.statusCode != 200) {
      throw Exception('Failed to download template: HTTP ${response.statusCode}');
    }
    
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    final repoName = _extractRepoNameFromUrl(url);
    final templatePrefix = '$repoName/lib/core/';

    print('Extracting core modules from template...');

    bool foundFiles = false;
    for (final file in archive) {
      if (file.name.startsWith(templatePrefix)) {
        foundFiles = true;
        final relativePath = file.name.substring(templatePrefix.length);
        final filePath = path.join('lib/core', relativePath);

        if (file.isFile) {
          final outputFile = File(filePath);
          outputFile.createSync(recursive: true);
          outputFile.writeAsBytesSync(file.content as List<int>);
          print('Created file: $filePath');
        } else if (file is Directory) {
          final outputDir = Directory(filePath);
          outputDir.createSync(recursive: true);
          print('Created directory: $filePath');
        }
      }
    }
    
    if (!foundFiles) {
      print('Warning: No core files found in template. Available files in archive:');
      for (final file in archive) {
        if (file.name.contains('core/')) {
          print('  ${file.name}');
        }
      }
    } else {
      print('✅ Core modules extracted successfully from template!');
    }
  } catch (e) {
    print('Error while generating core from template: $e');
    if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
      print('This appears to be an SSL certificate issue. Try using --insecure flag or ensure SSL certificates are properly configured.');
    }
  }
}

/// Generate specific module from template
Future<void> generateModuleFromTemplate(String moduleName, {String? repoUrl, bool insecure = false}) async {
  try {
    final url = repoUrl ?? 'https://github.com/farooq958/cli_template/archive/refs/heads/master.zip';
    print('Downloading template from: $url');
    
    // Create HTTP client
    final httpClient = CustomHttpClient.createClient(insecure: insecure);
    if (insecure) {
      print('Warning: SSL certificate verification is disabled for this request');
    }
    final response = await httpClient.get(Uri.parse(url));
    httpClient.close();
    
    if (response.statusCode != 200) {
      throw Exception('Failed to download template: HTTP ${response.statusCode}');
    }
    
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    final repoName = _extractRepoNameFromUrl(url);
    final templatePrefix = '$repoName/lib/core/$moduleName/';

    print('Extracting $moduleName module from template...');

    bool foundFiles = false;
    for (final file in archive) {
      if (file.name.startsWith(templatePrefix)) {
        foundFiles = true;
        final relativePath = file.name.substring(templatePrefix.length);
        final filePath = path.join('lib/core', moduleName, relativePath);

        if (file.isFile) {
          final outputFile = File(filePath);
          outputFile.createSync(recursive: true);
          outputFile.writeAsBytesSync(file.content as List<int>);
          print('Created file: $filePath');
        } else if (file is Directory) {
          final outputDir = Directory(filePath);
          outputDir.createSync(recursive: true);
          print('Created directory: $filePath');
        }
      }
    }
    
    if (!foundFiles) {
      print('Warning: No $moduleName files found in template. Available files in archive:');
      for (final file in archive) {
        if (file.name.contains('core/$moduleName/')) {
          print('  ${file.name}');
        }
      }
    } else {
      print('✅ $moduleName module extracted successfully from template!');
    }
  } catch (e) {
    print('Error while generating $moduleName from template: $e');
    if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
      print('This appears to be an SSL certificate issue. Try using --insecure flag or ensure SSL certificates are properly configured.');
    }
  }
}

/// Generate feature from template
Future<void> generateFeatureFromTemplate(String featureName, {String? repoUrl, bool insecure = false}) async {
  try {
    print('Creating feature: $featureName');
    
    // Create the complete feature structure locally
    await _createFeatureStructure(featureName);
    
    print('✅ Feature "$featureName" created successfully!');
    print('📁 Location: lib/features/$featureName');
  } catch (e) {
    print('Error while generating feature: $e');
  }
}

/// Create complete feature structure locally
Future<void> _createFeatureStructure(String featureName) async {
  final featureDir = Directory('lib/features/$featureName');
  if (featureDir.existsSync()) {
    print('Feature directory already exists: ${featureDir.path}');
    return;
  }
  
  // Create directory structure
  final dataDir = Directory('lib/features/$featureName/data');
  final domainDir = Directory('lib/features/$featureName/domain');
  final presentationDir = Directory('lib/features/$featureName/presentation');
  
  dataDir.createSync(recursive: true);
  domainDir.createSync(recursive: true);
  presentationDir.createSync(recursive: true);
  
  // Create subdirectories
  Directory('lib/features/$featureName/data/data_sources').createSync(recursive: true);
  Directory('lib/features/$featureName/data/database/tables').createSync(recursive: true);
  Directory('lib/features/$featureName/data/mappers').createSync(recursive: true);
  Directory('lib/features/$featureName/data/models').createSync(recursive: true);
  Directory('lib/features/$featureName/data/repositories').createSync(recursive: true);
  
  Directory('lib/features/$featureName/domain/entities').createSync(recursive: true);
  Directory('lib/features/$featureName/domain/repositories').createSync(recursive: true);
  Directory('lib/features/$featureName/domain/use_cases').createSync(recursive: true);
  
  Directory('lib/features/$featureName/presentation/cubit').createSync(recursive: true);
  Directory('lib/features/$featureName/presentation/pages').createSync(recursive: true);
  Directory('lib/features/$featureName/presentation/widgets').createSync(recursive: true);
  
  // Generate files
  await _generateDataLayerFiles(featureName);
  await _generateDomainLayerFiles(featureName);
  await _generatePresentationLayerFiles(featureName);
  await _generateInjectionFile(featureName);
}

/// Generate data layer files
Future<void> _generateDataLayerFiles(String featureName) async {
  final pascalCase = _toPascalCase(featureName);
  final singularPascal = _toSingularPascalCase(featureName);
  final singular = _toSingular(featureName);
  
  // Local data source
  final localDataSource = File('lib/features/$featureName/data/data_sources/${singular}_local_data_source.dart');
  localDataSource.writeAsStringSync('''
abstract class ${singularPascal}LocalDataSource {
  Future<List<$pascalCase>> get${pascalCase}s();
  Future<$pascalCase> get${singularPascal}ById(String id);
}
''');
  
  // Local data source implementation
  final localDataSourceImpl = File('lib/features/$featureName/data/data_sources/${singular}_local_data_source_impl.dart');
  localDataSourceImpl.writeAsStringSync('''
import 'package:drift/drift.dart';
import '../database/tables/${featureName}_table.dart';
import '../models/${singular}_model.dart';
import '${singular}_local_data_source.dart';

class ${singularPascal}LocalDataSourceImpl implements ${singularPascal}LocalDataSource {
  final Database database;
  
  ${singularPascal}LocalDataSourceImpl(this.database);
  
  @override
  Future<List<$pascalCase>> get${pascalCase}s() async {
    final result = await database.select(database.${featureName}Table).get();
    return result.map((e) => $pascalCase.fromTableData(e)).toList();
  }
  
  @override
  Future<$pascalCase> get${singularPascal}ById(String id) async {
    final result = await (database.select(database.${featureName}Table)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    
    if (result == null) throw Exception('$singular not found');
    return $pascalCase.fromTableData(result);
  }
  
  @override
  Future<void> save${pascalCase}($pascalCase ${singular}) async {
    await database.into(database.${featureName}Table).insert(
      ${featureName}TableCompanion.insert(
        id: Value(${singular}.id),
        name: Value(${singular}.name),
        createdAt: Value(DateTime.now()),
      ),
    );
  }
  
  @override
  Future<void> delete${singularPascal}(String id) async {
    await (database.delete(database.${featureName}Table)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
''');
  
  // Remote data source
  final remoteDataSource = File('lib/features/$featureName/data/data_sources/${singular}_remote_data_source.dart');
  remoteDataSource.writeAsStringSync('''
import '../models/${singular}_model.dart';

abstract class ${singularPascal}RemoteDataSource {
  Future<List<$pascalCase>> get${pascalCase}s();
  Future<$pascalCase> get${singularPascal}ById(String id);
  Future<$pascalCase> create${pascalCase}(Map<String, dynamic> data);
  Future<$pascalCase> update${pascalCase}(String id, Map<String, dynamic> data);
  Future<void> delete${singularPascal}(String id);
}
''');
  
  // Remote data source implementation
  final remoteDataSourceImpl = File('lib/features/$featureName/data/data_sources/${singular}_remote_data_source_impl.dart');
  remoteDataSourceImpl.writeAsStringSync('''
import 'package:dio/dio.dart';
import '../models/${singular}_model.dart';
import '${singular}_remote_data_source.dart';

class ${singularPascal}RemoteDataSourceImpl implements ${singularPascal}RemoteDataSource {
  final Dio _dio;
  
  ${singularPascal}RemoteDataSourceImpl(this._dio);
  
  @override
  Future<List<$pascalCase>> get${pascalCase}s() async {
    try {
      final response = await _dio.get('/${featureName}');
      return (response.data as List)
          .map((json) => $pascalCase.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load ${featureName}: \${e.message}');
    }
  }
  
  @override
  Future<$pascalCase> get${singularPascal}ById(String id) async {
    try {
      final response = await _dio.get('/${featureName}/\$id');
      return $pascalCase.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load $singular: \${e.message}');
    }
  }
  
  @override
  Future<$pascalCase> create${pascalCase}(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/${featureName}', data: data);
      return $pascalCase.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create $singular: \${e.message}');
    }
  }
  
  @override
  Future<$pascalCase> update${pascalCase}(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/${featureName}/\$id', data: data);
      return $pascalCase.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update $singular: \${e.message}');
    }
  }
  
  @override
  Future<void> delete${singularPascal}(String id) async {
    try {
      await _dio.delete('/${featureName}/\$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete $singular: \${e.message}');
    }
  }
}
''');
  
  // Database table
  final tableFile = File('lib/features/$featureName/data/database/tables/${featureName}_table.dart');
  tableFile.writeAsStringSync('''
import 'package:drift/drift.dart';

@DataClassName('${singular}TableData')
class ${featureName}Table extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
''');
  
  // Mapper
  final mapperFile = File('lib/features/$featureName/data/mappers/${singular}_mapper.dart');
  mapperFile.writeAsStringSync('''
import '../models/${singular}_model.dart';
import '../database/tables/${featureName}_table.dart';

extension ${singularPascal}Mapper on ${singular}TableData {
  $pascalCase toModel() {
    return $pascalCase(
      id: id,
      name: name,
      createdAt: createdAt,
    );
  }
}

extension ${pascalCase}Mapper on $pascalCase {
  ${singular}TableData toTableData() {
    return ${singular}TableData(
      id: id,
      name: name,
      createdAt: createdAt,
    );
  }
}
''');
  
  // Model
  final modelFile = File('lib/features/$featureName/data/models/${singular}_model.dart');
  modelFile.writeAsStringSync('''
import '../../domain/entities/${singular}_entity.dart';

class $pascalCase extends ${singularPascal}Entity {
  const $pascalCase({
    required super.id,
    required super.name,
    required super.createdAt,
  });
  
  factory $pascalCase.fromJson(Map<String, dynamic> json) {
    return $pascalCase(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory $pascalCase.fromTableData(${singular}TableData data) {
    return $pascalCase(
      id: data.id,
      name: data.name,
      createdAt: data.createdAt,
    );
  }
}
''');
  
  // Response model
  final responseFile = File('lib/features/$featureName/data/models/${featureName}_response.dart');
  responseFile.writeAsStringSync('''
class ${pascalCase}Response {
  final List<$pascalCase> ${featureName};
  final int total;
  final int page;
  
  const ${pascalCase}Response({
    required this.${featureName},
    required this.total,
    required this.page,
  });
  
  factory ${pascalCase}Response.fromJson(Map<String, dynamic> json) {
    return ${pascalCase}Response(
      ${featureName}: (json['data'] as List)
          .map((item) => $pascalCase.fromJson(item))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
    );
  }
}
''');
  
  // Repository implementation
  final repoImplFile = File('lib/features/$featureName/data/repositories/${singular}_repository_impl.dart');
  repoImplFile.writeAsStringSync('''
import '../../domain/repositories/${singular}_repository.dart';
import '../data_sources/${singular}_local_data_source.dart';
import '../data_sources/${singular}_remote_data_source.dart';
import '../models/${singular}_model.dart';

class ${singularPascal}RepositoryImpl implements ${singularPascal}Repository {
  final ${singularPascal}LocalDataSource localDataSource;
  final ${singularPascal}RemoteDataSource remoteDataSource;
  
  ${singularPascal}RepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });
  
  @override
  Future<List<$pascalCase>> get${pascalCase}s() async {
    try {
      final remote${pascalCase}s = await remoteDataSource.get${pascalCase}s();
      // Cache locally
      for (final ${singular} in remote${pascalCase}s) {
        await localDataSource.save${pascalCase}(${singular});
      }
      return remote${pascalCase}s;
    } catch (e) {
      // Fallback to local data
      return await localDataSource.get${pascalCase}s();
    }
  }
  
  @override
  Future<$pascalCase> get${singularPascal}ById(String id) async {
    try {
      return await remoteDataSource.get${singularPascal}ById(id);
    } catch (e) {
      // Fallback to local data
      return await localDataSource.get${singularPascal}ById(id);
    }
  }
  
  @override
  Future<$pascalCase> create${pascalCase}(Map<String, dynamic> data) async {
    final ${singular} = await remoteDataSource.create${pascalCase}(data);
    await localDataSource.save${pascalCase}(${singular});
    return ${singular};
  }
  
  @override
  Future<$pascalCase> update${pascalCase}(String id, Map<String, dynamic> data) async {
    final ${singular} = await remoteDataSource.update${pascalCase}(id, data);
    await localDataSource.save${pascalCase}(${singular});
    return ${singular};
  }
  
  @override
  Future<void> delete${singularPascal}(String id) async {
    await remoteDataSource.delete${singularPascal}(id);
    await localDataSource.delete${singularPascal}(id);
  }
}
''');
}

/// Generate domain layer files
Future<void> _generateDomainLayerFiles(String featureName) async {
  final pascalCase = _toPascalCase(featureName);
  final singularPascal = _toSingularPascalCase(featureName);
  final singular = _toSingular(featureName);
  
  // Entity
  final entityFile = File('lib/features/$featureName/domain/entities/${singular}_entity.dart');
  entityFile.writeAsStringSync('''
import 'package:equatable/equatable.dart';

class ${singularPascal}Entity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  
  const ${singularPascal}Entity({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  
  @override
  List<Object?> get props => [id, name, createdAt];
  
  ${singularPascal}Entity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return ${singularPascal}Entity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
''');
  
  // List entity
  final listEntityFile = File('lib/features/$featureName/domain/entities/${featureName}_list.dart');
  listEntityFile.writeAsStringSync('''
import 'package:equatable/equatable.dart';
import '${singular}_entity.dart';

class ${pascalCase}List extends Equatable {
  final List<${singularPascal}Entity> ${featureName};
  final bool hasReachedMax;
  
  const ${pascalCase}List({
    required this.${featureName},
    this.hasReachedMax = false,
  });
  
  @override
  List<Object?> get props => [${featureName}, hasReachedMax];
  
  ${pascalCase}List copyWith({
    List<${singularPascal}Entity>? ${featureName},
    bool? hasReachedMax,
  }) {
    return ${pascalCase}List(
      ${featureName}: ${featureName} ?? this.${featureName},
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}
''');
  
  // Repository interface
  final repoInterfaceFile = File('lib/features/$featureName/domain/repositories/${singular}_repository.dart');
  repoInterfaceFile.writeAsStringSync('''
import '../entities/${singular}_entity.dart';

abstract class ${singularPascal}Repository {
  Future<List<${singularPascal}Entity>> get${pascalCase}s();
  Future<${singularPascal}Entity> get${singularPascal}ById(String id);
  Future<${singularPascal}Entity> create${pascalCase}(Map<String, dynamic> data);
  Future<${singularPascal}Entity> update${pascalCase}(String id, Map<String, dynamic> data);
  Future<void> delete${singularPascal}(String id);
}
''');
  
  // Use case
  final useCaseFile = File('lib/features/$featureName/domain/use_cases/get_${featureName}_use_case.dart');
  useCaseFile.writeAsStringSync('''
import '../entities/${singular}_entity.dart';
import '../repositories/${singular}_repository.dart';

class Get${pascalCase}UseCase {
  final ${singularPascal}Repository repository;
  
  Get${pascalCase}UseCase(this.repository);
  
  Future<List<${singularPascal}Entity>> call() async {
    return await repository.get${pascalCase}s();
  }
}

class Get${singularPascal}ByIdUseCase {
  final ${singularPascal}Repository repository;
  
  Get${singularPascal}ByIdUseCase(this.repository);
  
  Future<${singularPascal}Entity> call(String id) async {
    return await repository.get${singularPascal}ById(id);
  }
}

class Create${pascalCase}UseCase {
  final ${singularPascal}Repository repository;
  
  Create${pascalCase}UseCase(this.repository);
  
  Future<${singularPascal}Entity> call(Map<String, dynamic> data) async {
    return await repository.create${pascalCase}(data);
  }
}

class Update${pascalCase}UseCase {
  final ${singularPascal}Repository repository;
  
  Update${pascalCase}UseCase(this.repository);
  
  Future<${singularPascal}Entity> call(String id, Map<String, dynamic> data) async {
    return await repository.update${pascalCase}(id, data);
  }
}

class Delete${pascalCase}UseCase {
  final ${singularPascal}Repository repository;
  
  Delete${pascalCase}UseCase(this.repository);
  
  Future<void> call(String id) async {
    return await repository.delete${singularPascal}(id);
  }
}
''');
}

/// Generate presentation layer files
Future<void> _generatePresentationLayerFiles(String featureName) async {
  final pascalCase = _toPascalCase(featureName);
  final singularPascal = _toSingularPascalCase(featureName);
  final singular = _toSingular(featureName);
  
  // Cubit
  final cubitFile = File('lib/features/$featureName/presentation/cubit/${featureName}_cubit.dart');
  cubitFile.writeAsStringSync('''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/use_cases/get_${featureName}_use_case.dart';
import '../../domain/entities/${singular}_entity.dart';

part '${featureName}_state.dart';
part '${featureName}_state.freezed.dart';

class ${pascalCase}Cubit extends Cubit<${pascalCase}State> {
  final Get${pascalCase}UseCase _get${pascalCase}UseCase;
  final Get${singularPascal}ByIdUseCase _get${singularPascal}ByIdUseCase;
  final Create${pascalCase}UseCase _create${pascalCase}UseCase;
  final Update${pascalCase}UseCase _update${pascalCase}UseCase;
  final Delete${pascalCase}UseCase _delete${pascalCase}UseCase;
  
  ${pascalCase}Cubit({
    required Get${pascalCase}UseCase get${pascalCase}UseCase,
    required Get${singularPascal}ByIdUseCase get${singularPascal}ByIdUseCase,
    required Create${pascalCase}UseCase create${pascalCase}UseCase,
    required Update${pascalCase}UseCase update${pascalCase}UseCase,
    required Delete${pascalCase}UseCase delete${pascalCase}UseCase,
  }) : _get${pascalCase}UseCase = get${pascalCase}UseCase,
       _get${singularPascal}ByIdUseCase = get${singularPascal}ByIdUseCase,
       _create${pascalCase}UseCase = create${pascalCase}UseCase,
       _update${pascalCase}UseCase = update${pascalCase}UseCase,
       _delete${pascalCase}UseCase = delete${pascalCase}UseCase,
       super(const ${pascalCase}State.initial());
  
  Future<void> load${pascalCase}s() async {
    emit(const ${pascalCase}State.loading());
    try {
      final ${featureName} = await _get${pascalCase}UseCase();
      emit(${pascalCase}State.loaded(${featureName}));
    } catch (e) {
      emit(${pascalCase}State.error(e.toString()));
    }
  }
  
  Future<void> load${singularPascal}ById(String id) async {
    emit(const ${pascalCase}State.loading());
    try {
      final ${singular} = await _get${singularPascal}ByIdUseCase(id);
      emit(${pascalCase}State.loaded([${singular}]));
    } catch (e) {
      emit(${pascalCase}State.error(e.toString()));
    }
  }
  
  Future<void> create${pascalCase}(Map<String, dynamic> data) async {
    try {
      await _create${pascalCase}UseCase(data);
      await load${pascalCase}s();
    } catch (e) {
      emit(${pascalCase}State.error(e.toString()));
    }
  }
  
  Future<void> update${pascalCase}(String id, Map<String, dynamic> data) async {
    try {
      await _update${pascalCase}UseCase(id, data);
      await load${pascalCase}s();
    } catch (e) {
      emit(${pascalCase}State.error(e.toString()));
    }
  }
  
  Future<void> delete${pascalCase}(String id) async {
    try {
      await _delete${pascalCase}UseCase(id);
      await load${pascalCase}s();
    } catch (e) {
      emit(${pascalCase}State.error(e.toString()));
    }
  }
}
''');
  
  // State
  final stateFile = File('lib/features/$featureName/presentation/cubit/${featureName}_state.dart');
  stateFile.writeAsStringSync('''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/${singular}_entity.dart';

part '${featureName}_state.freezed.dart';

@freezed
class ${pascalCase}State with _\$${pascalCase}State {
  const factory ${pascalCase}State.initial() = _Initial;
  const factory ${pascalCase}State.loading() = _Loading;
  const factory ${pascalCase}State.loaded(List<${singularPascal}Entity> ${featureName}) = _Loaded;
  const factory ${pascalCase}State.error(String message) = _Error;
}
''');
  
  // Page
  final pageFile = File('lib/features/$featureName/presentation/pages/${featureName}_page.dart');
  pageFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/${featureName}_cubit.dart';
import '../widgets/${singular}_card.dart';
import '../widgets/${featureName}_list.dart';

class ${pascalCase}Page extends StatelessWidget {
  const ${pascalCase}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ${pascalCase}Cubit(
        // TODO: Inject use cases
        get${pascalCase}UseCase: context.read(),
        get${singularPascal}ByIdUseCase: context.read(),
        create${pascalCase}UseCase: context.read(),
        update${pascalCase}UseCase: context.read(),
        delete${pascalCase}UseCase: context.read(),
      )..load${pascalCase}s(),
      child: const ${pascalCase}View(),
    );
  }
}

class ${pascalCase}View extends StatelessWidget {
  const ${pascalCase}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_toPascalCase('${featureName}')}'),
      ),
      body: BlocBuilder<${pascalCase}Cubit, ${pascalCase}State>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('Initial')),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (${featureName}) => ${pascalCase}List(${featureName}: ${featureName}),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: \$message'),
                  ElevatedButton(
                    onPressed: () => context.read<${pascalCase}Cubit>().load${pascalCase}s(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create/edit page
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
''');
  
  // Widget card
  final cardWidgetFile = File('lib/features/$featureName/presentation/widgets/${singular}_card.dart');
  cardWidgetFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import '../../domain/entities/${singular}_entity.dart';

class ${singularPascal}Card extends StatelessWidget {
  final ${singularPascal}Entity ${singular};
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  
  const ${singularPascal}Card({
    super.key,
    required this.${singular},
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(${singular}.name),
        subtitle: Text('Created: \${${singular}.createdAt.toString().split(' ')[0]}'),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
''');
  
  // Widget list
  final listWidgetFile = File('lib/features/$featureName/presentation/widgets/${featureName}_list.dart');
  listWidgetFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/${singular}_entity.dart';
import '../cubit/${featureName}_cubit.dart';
import '${singular}_card.dart';

class ${pascalCase}List extends StatelessWidget {
  final List<${singularPascal}Entity> ${featureName};
  
  const ${pascalCase}List({
    super.key,
    required this.${featureName},
  });

  @override
  Widget build(BuildContext context) {
    if (${featureName}.isEmpty) {
      return const Center(
        child: Text('No ${featureName} found'),
      );
    }
    
    return ListView.builder(
      itemCount: ${featureName}.length,
      itemBuilder: (context, index) {
        final ${singular} = ${featureName}[index];
        return ${singularPascal}Card(
          ${singular}: ${singular},
          onTap: () {
            // TODO: Navigate to detail page
          },
          onDelete: () {
            _showDeleteDialog(context, ${singular});
          },
        );
      },
    );
  }
  
  void _showDeleteDialog(BuildContext context, ${singularPascal}Entity ${singular}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_toSingular('${featureName}')}'),
        content: Text('Are you sure you want to delete \${${singular}.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<${pascalCase}Cubit>().delete${pascalCase}(${singular}.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

String _toSingular(String input) {
  if (input.endsWith('s')) {
    return input.substring(0, input.length - 1);
  }
  return input;
}
''');
}

/// Generate injection file
Future<void> _generateInjectionFile(String featureName) async {
  final pascalCase = _toPascalCase(featureName);
  final singularPascal = _toSingularPascalCase(featureName);
  final singular = _toSingular(featureName);
  
  final injectionFile = File('lib/features/$featureName/${featureName}_injection.dart');
  injectionFile.writeAsStringSync('''
import 'package:get_it/get_it.dart';
import '../data/data_sources/${singular}_local_data_source_impl.dart';
import '../data/data_sources/${singular}_remote_data_source_impl.dart';
import '../data/repositories/${singular}_repository_impl.dart';
import '../domain/repositories/${singular}_repository.dart';
import '../domain/use_cases/get_${featureName}_use_case.dart';
import '../presentation/cubit/${featureName}_cubit.dart';

Future<void> inject${pascalCase}(GetIt sl) async {
  // Data sources
  sl.registerLazySingleton<${singularPascal}LocalDataSource>(
    () => ${singularPascal}LocalDataSourceImpl(sl()),
  );
  
  sl.registerLazySingleton<${singularPascal}RemoteDataSource>(
    () => ${singularPascal}RemoteDataSourceImpl(sl()),
  );
  
  // Repository
  sl.registerLazySingleton<${singularPascal}Repository>(
    () => ${singularPascal}RepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  
  // Use cases
  sl.registerLazySingleton<Get${pascalCase}UseCase>(
    () => Get${pascalCase}UseCase(sl()),
  );
  
  sl.registerLazySingleton<Get${singularPascal}ByIdUseCase>(
    () => Get${singularPascal}ByIdUseCase(sl()),
  );
  
  sl.registerLazySingleton<Create${pascalCase}UseCase>(
    () => Create${pascalCase}UseCase(sl()),
  );
  
  sl.registerLazySingleton<Update${pascalCase}UseCase>(
    () => Update${pascalCase}UseCase(sl()),
  );
  
  sl.registerLazySingleton<Delete${pascalCase}UseCase>(
    () => Delete${pascalCase}UseCase(sl()),
  );
  
  // Cubit
  sl.registerFactory<${pascalCase}Cubit>(
    () => ${pascalCase}Cubit(
      get${pascalCase}UseCase: sl(),
      get${singularPascal}ByIdUseCase: sl(),
      create${pascalCase}UseCase: sl(),
      update${pascalCase}UseCase: sl(),
      delete${pascalCase}UseCase: sl(),
    ),
  );
}
''');
}

/// Convert string to PascalCase
String _toPascalCase(String input) {
  return input.split('_').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join('');
}

/// Convert string to singular form (basic implementation)
String _toSingular(String input) {
  if (input.endsWith('s')) {
    return input.substring(0, input.length - 1);
  }
  return input;
}

/// Convert string to singular PascalCase
String _toSingularPascalCase(String input) {
  final singular = _toSingular(input);
  return _toPascalCase(singular);
}

/// Generate core folder structure
void generateCoreFolder() {
  final coreDir = Directory('lib/core');
  if (!coreDir.existsSync()) {
    coreDir.createSync(recursive: true);
    print('Created core folder: ${coreDir.path}');
  } else {
    print('Core folder already exists: ${coreDir.path}');
  }
}

/// Generate all core modules
void generateAllCoreModules() {
  generateThemeModule();
  generateNetworkModule();
  generateStorageModule();
  generateRouterModule();
  generateDIModule();
  generateConstantsModule();
  generateUtilsModule();
  generateWidgetsModule();
  generateLocalizationModule();
  generateConfigModule();
}

/// Generate theme module
void generateThemeModule() {
  generateCoreFolder();
  
  final themeDir = Directory('lib/core/theme');
  themeDir.createSync(recursive: true);
  
  // Create app_colors.dart
  final colorsFile = File('lib/core/theme/app_colors.dart');
  colorsFile.writeAsStringSync('''
import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color? primary;
  final Color? secondary;
  final Color? surface;
  final Color? background;
  final Color? error;
  final Color? onPrimary;
  final Color? onSecondary;
  final Color? onSurface;
  final Color? onBackground;
  final Color? onError;

  const AppColors({
    this.primary,
    this.secondary,
    this.surface,
    this.background,
    this.error,
    this.onPrimary,
    this.onSecondary,
    this.onSurface,
    this.onBackground,
    this.onError,
  });

  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? background,
    Color? error,
    Color? onPrimary,
    Color? onSecondary,
    Color? onSurface,
    Color? onBackground,
    Color? onError,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      error: error ?? this.error,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      onBackground: onBackground ?? this.onBackground,
      onError: onError ?? this.onError,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    
    return AppColors(
      primary: Color.lerp(primary, other.primary, t),
      secondary: Color.lerp(secondary, other.secondary, t),
      surface: Color.lerp(surface, other.surface, t),
      background: Color.lerp(background, other.background, t),
      error: Color.lerp(error, other.error, t),
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t),
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t),
      onSurface: Color.lerp(onSurface, other.onSurface, t),
      onBackground: Color.lerp(onBackground, other.onBackground, t),
      onError: Color.lerp(onError, other.onError, t),
    );
  }

  static const AppColors light = AppColors(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFF03DAC6),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFF5F5F5),
    error: Color(0xFFD32F2F),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),
    onSurface: Color(0xFF000000),
    onBackground: Color(0xFF000000),
    onError: Color(0xFFFFFFFF),
  );

  static const AppColors dark = AppColors(
    primary: Color(0xFF90CAF9),
    secondary: Color(0xFF03DAC6),
    surface: Color(0xFF121212),
    background: Color(0xFF121212),
    error: Color(0xFFCF6679),
    onPrimary: Color(0xFF000000),
    onSecondary: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
  );
}
''');
  print('Created: lib/core/theme/app_colors.dart');

  // Create app_theme.dart
  final themeFile = File('lib/core/theme/app_theme.dart');
  themeFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.light.primary!,
      brightness: Brightness.light,
    ),
    extensions: [AppColors.light],
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.dark.primary!,
      brightness: Brightness.dark,
    ),
    extensions: [AppColors.dark],
  );
}
''');
  print('Created: lib/core/theme/app_theme.dart');
}

/// Generate network module
void generateNetworkModule() {
  generateCoreFolder();
  
  final networkDir = Directory('lib/core/network');
  networkDir.createSync(recursive: true);
  
  // Create api_client.dart
  final apiClientFile = File('lib/core/network/api_client.dart');
  apiClientFile.writeAsStringSync('''
import 'package:dio/dio.dart';
import 'api_config.dart';
import 'api_logger_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.headers,
    ));

    _dio.interceptors.addAll([
      ApiLoggerInterceptor(),
      if (ApiConfig.enableLogging) LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
      ),
    ]);
  }

  // GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return e.response?.data?['message'] ?? 'Bad response';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error';
      case DioExceptionType.unknown:
        return 'Unknown error: \${e.message}';
    }
  }
}

class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => message;
}
''');
  print('Created: lib/core/network/api_client.dart');

  // Create api_config.dart
  final apiConfigFile = File('lib/core/network/api_config.dart');
  apiConfigFile.writeAsStringSync('''
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl = kDebugMode 
      ? 'https://api.example.com/dev'
      : 'https://api.example.com/prod';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const bool enableLogging = kDebugMode;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
''');
  print('Created: lib/core/network/api_config.dart');

  // Create api_logger_interceptor.dart
  final loggerInterceptorFile = File('lib/core/network/api_logger_interceptor.dart');
  loggerInterceptorFile.writeAsStringSync('''
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiLoggerInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('API Request: \${options.method} \${options.uri}');
    if (options.data != null) {
      _logger.d('Request data: \${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('API Response: \${response.statusCode} \${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('API Error: \${err.message}');
    super.onError(err, handler);
  }
}
''');
  print('Created: lib/core/network/api_logger_interceptor.dart');

  // Create app_urls.dart
  final urlsFile = File('lib/core/network/app_urls.dart');
  urlsFile.writeAsStringSync('''
class AppUrls {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // User endpoints
  static const String users = '/users';
  static String userById(String id) => '/users/\$id';
  static String updateUser(String id) => '/users/\$id';

  // Add more endpoints as needed
}
''');
  print('Created: lib/core/network/app_urls.dart');
}

/// Generate storage module
void generateStorageModule() {
  generateCoreFolder();
  
  final storageDir = Directory('lib/core/storage');
  storageDir.createSync(recursive: true);
  
  // Create app_pref.dart (abstract)
  final prefFile = File('lib/core/storage/app_pref.dart');
  prefFile.writeAsStringSync('''
abstract class AppPref {
  // Theme
  Future<bool> setThemeMode(String themeMode);
  String getThemeMode();

  // Language
  Future<bool> setLanguage(String languageCode);
  String getLanguage();

  // Auth
  Future<bool> setAuthToken(String token);
  String? getAuthToken();
  Future<bool> clearAuthToken();

  // User data
  Future<bool> setUserId(String userId);
  String? getUserId();
  Future<bool> clearUserId();

  // App settings
  Future<bool> setFirstLaunch(bool isFirstLaunch);
  bool isFirstLaunch();

  // Clear all data
  Future<bool> clearAll();
}
''');
  print('Created: lib/core/storage/app_pref.dart');

  // Create app_pref_impl.dart
  final prefImplFile = File('lib/core/storage/app_pref_impl.dart');
  prefImplFile.writeAsStringSync('''
import 'package:shared_preferences/shared_preferences.dart';
import 'app_pref.dart';
import 'app_pref_keys.dart';

class AppPrefImpl implements AppPref {
  final SharedPreferences _prefs;

  AppPrefImpl(this._prefs);

  @override
  Future<bool> setThemeMode(String themeMode) async {
    return await _prefs.setString(AppPrefKeys.themeMode, themeMode);
  }

  @override
  String getThemeMode() {
    return _prefs.getString(AppPrefKeys.themeMode) ?? 'system';
  }

  @override
  Future<bool> setLanguage(String languageCode) async {
    return await _prefs.setString(AppPrefKeys.language, languageCode);
  }

  @override
  String getLanguage() {
    return _prefs.getString(AppPrefKeys.language) ?? 'en';
  }

  @override
  Future<bool> setAuthToken(String token) async {
    return await _prefs.setString(AppPrefKeys.authToken, token);
  }

  @override
  String? getAuthToken() {
    return _prefs.getString(AppPrefKeys.authToken);
  }

  @override
  Future<bool> clearAuthToken() async {
    return await _prefs.remove(AppPrefKeys.authToken);
  }

  @override
  Future<bool> setUserId(String userId) async {
    return await _prefs.setString(AppPrefKeys.userId, userId);
  }

  @override
  String? getUserId() {
    return _prefs.getString(AppPrefKeys.userId);
  }

  @override
  Future<bool> clearUserId() async {
    return await _prefs.remove(AppPrefKeys.userId);
  }

  @override
  Future<bool> setFirstLaunch(bool isFirstLaunch) async {
    return await _prefs.setBool(AppPrefKeys.firstLaunch, isFirstLaunch);
  }

  @override
  bool isFirstLaunch() {
    return _prefs.getBool(AppPrefKeys.firstLaunch) ?? true;
  }

  @override
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
''');
  print('Created: lib/core/storage/app_pref_impl.dart');

  // Create app_pref_keys.dart
  final prefKeysFile = File('lib/core/storage/app_pref_keys.dart');
  prefKeysFile.writeAsStringSync('''
class AppPrefKeys {
  // Theme
  static const String themeMode = 'theme_mode';

  // Language
  static const String language = 'language';

  // Auth
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';

  // App settings
  static const String firstLaunch = 'first_launch';

  // Add more keys as needed
}
''');
  print('Created: lib/core/storage/app_pref_keys.dart');

  // Create app_pref_export.dart
  final prefExportFile = File('lib/core/storage/app_pref_export.dart');
  prefExportFile.writeAsStringSync('''
// Storage exports
export 'app_pref.dart';
export 'app_pref_keys.dart';
''');
  print('Created: lib/core/storage/app_pref_export.dart');
}

/// Generate router module
void generateRouterModule() {
  generateCoreFolder();
  
  final routerDir = Directory('lib/core/router');
  routerDir.createSync(recursive: true);
  
  // Create app_routes.dart
  final routesFile = File('lib/core/router/app_routes.dart');
  routesFile.writeAsStringSync('''
class AppRoutes {
  // Splash
  static const String splash = '/';
  static const String splashName = 'splash';

  // Auth
  static const String login = '/login';
  static const String loginName = 'login';
  static const String register = '/register';
  static const String registerName = 'register';

  // Main
  static const String home = '/home';
  static const String homeName = 'home';
  static const String profile = '/profile';
  static const String profileName = 'profile';
  static const String settings = '/settings';
  static const String settingsName = 'settings';

  // Utility method to build path with parameters
  static String path(String route) => route;
  
  // Utility method to build path with parameters
  static String pathWithParams(String route, Map<String, String> params) {
    String path = route;
    params.forEach((key, value) {
      path = path.replaceFirst(':\$key', value);
    });
    return path;
  }
}
''');
  print('Created: lib/core/router/app_routes.dart');

  // Create app_router.dart
  final routerFile = File('lib/core/router/app_router.dart');
  routerFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: \${state.error}'),
      ),
    ),
  );
}

// Placeholder widgets - replace with your actual screens
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Splash Screen'),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Login Screen'),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Register Screen'),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Screen'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Settings Screen'),
      ),
    );
  }
}
''');
  print('Created: lib/core/router/app_router.dart');
}

/// Generate dependency injection module
void generateDIModule() {
  generateCoreFolder();
  generateBaseUseCase();
  
  final diDir = Directory('lib/core/di');
  diDir.createSync(recursive: true);
  
  // Create dependency_injection.dart
  final diFile = File('lib/core/di/dependency_injection.dart');
  diFile.writeAsStringSync('''
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../storage/app_pref.dart';
import '../storage/app_pref_impl.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencyInjection() async {
  await _initCore();
  // Add feature dependencies here
  // await _initFeatures();
}

Future<void> _initCore() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Storage
  sl.registerLazySingleton<AppPref>(() => AppPrefImpl(sl<SharedPreferences>()));

  // Network
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
}

// Future<void> _initFeatures() async {
//   // Register feature dependencies here
//   initAuthInjector();
//   initUserInjector();
//   // Add more features here
// }

// Clean up resources
Future<void> disposeDependencyInjection() async {
  await sl.reset();
}
''');
  print('Created: lib/core/di/dependency_injection.dart');

  // Create di_export.dart
  final diExportFile = File('lib/core/di/di_export.dart');
  diExportFile.writeAsStringSync('''
// Dependency injection exports
export 'dependency_injection.dart';
''');
  print('Created: lib/core/di/di_export.dart');
}

/// Generate constants module
void generateConstantsModule() {
  generateCoreFolder();
  
  final constantsDir = Directory('lib/core/constants');
  constantsDir.createSync(recursive: true);
  
  // Create app_constants.dart
  final constantsFile = File('lib/core/constants/app_constants.dart');
  constantsFile.writeAsStringSync('''
class AppConstants {
  // App info
  static const String appName = 'My App';
  static const String appVersion = '1.0.0';

  // API
  static const int apiTimeout = 30;
  static const int maxRetryAttempts = 3;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100;

  // UI
  static const double defaultRadius = 8.0;
  static const double largeRadius = 16.0;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 50;

  // Storage
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
}
''');
  print('Created: lib/core/constants/app_constants.dart');

  // Create app_strings.dart
  final stringsFile = File('lib/core/constants/app_strings.dart');
  stringsFile.writeAsStringSync('''
class AppStrings {
  // General
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String done = 'Done';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String search = 'Search';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String info = 'Info';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String username = 'Username';
  static const String forgotPassword = 'Forgot Password?';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String welcome = 'Welcome';
  static const String welcomeBack = 'Welcome Back';

  // Validation
  static const String required = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String invalidUsername = 'Please enter a valid username';

  // Navigation
  static const String home = 'Home';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String help = 'Help';
  static const String about = 'About';

  // Messages
  static const String noDataFound = 'No data found';
  static const String somethingWentWrong = 'Something went wrong';
  static const String checkInternetConnection = 'Please check your internet connection';
  static const String tryAgain = 'Try Again';
  static const String retry = 'Retry';
}
''');
  print('Created: lib/core/constants/app_strings.dart');

  // Create app_sizes.dart
  final sizesFile = File('lib/core/constants/app_sizes.dart');
  sizesFile.writeAsStringSync('''
class AppSizes {
  // Padding
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // Margin
  static const double marginXS = 4.0;
  static const double marginSM = 8.0;
  static const double marginMD = 16.0;
  static const double marginLG = 24.0;
  static const double marginXL = 32.0;

  // Border radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // Icon sizes
  static const double iconXS = 12.0;
  static const double iconSM = 16.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // Button sizes
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 48.0;
  static const double buttonHeightLG = 56.0;

  // Avatar sizes
  static const double avatarXS = 24.0;
  static const double avatarSM = 32.0;
  static const double avatarMD = 48.0;
  static const double avatarLG = 64.0;
  static const double avatarXL = 96.0;

  // Screen breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
}
''');
  print('Created: lib/core/constants/app_sizes.dart');
}

/// Generate utils module
void generateUtilsModule() {
  generateCoreFolder();
  
  final utilsDir = Directory('lib/core/utils');
  utilsDir.createSync(recursive: true);
  
  // Create extensions.dart
  final extensionsFile = File('lib/core/utils/extensions.dart');
  extensionsFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// String extensions
extension StringExtensions on String {
  bool get isEmail => RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$').hasMatch(this);
  
  bool get isValidPassword => length >= 8;
  
  String capitalizeFirst() => isNotEmpty ? '\${this[0].toUpperCase()}\${substring(1)}' : '';
  
  String capitalizeWords() => split(' ').map((word) => word.capitalizeFirst()).join(' ');
  
  bool get isNumeric => double.tryParse(this) != null;
}

// DateTime extensions
extension DateTimeExtensions on DateTime {
  String get formattedDate => DateFormat('dd/MM/yyyy').format(this);
  
  String get formattedDateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inDays > 365) {
      return '\${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '\${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '\${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '\${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '\${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
  
  bool get isToday {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }
}

// BuildContext extensions
extension BuildContextExtensions on BuildContext {
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;
  
  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;
  
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  void hideKeyboard() => FocusScope.of(this).unfocus();
  
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

// Color extensions
extension ColorExtensions on Color {
  Color get opposite => computeLuminance() > 0.5 ? Colors.black : Colors.white;
  
  Color lighten(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
  
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
''');
  print('Created: lib/core/utils/extensions.dart');

  // Create validators.dart
  final validatorsFile = File('lib/core/utils/validators.dart');
  validatorsFile.writeAsStringSync('''
class Validators {
  // Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  // Password validator
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    if (!RegExp(r'(?=.*[!@#\$%^&*(),.?":{}|<>])').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // Confirm password validator
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Username validator
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (value.length > 50) {
      return 'Username must be less than 50 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+\$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  // Phone validator
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    if (!RegExp(r'^\+?[0-9]{10,15}\$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Required field validator
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '\$fieldName is required';
    }
    return null;
  }

  // Number validator
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    
    return null;
  }

  // URL validator
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    if (!RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)\$').hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
}
''');
  print('Created: lib/core/utils/validators.dart');

  // Create extensions_export.dart
  final extensionsExportFile = File('lib/core/utils/extensions_export.dart');
  extensionsExportFile.writeAsStringSync('''
// Utils exports
export 'extensions.dart';
export 'validators.dart';
''');
  print('Created: lib/core/utils/extensions_export.dart');
}

/// Generate widgets module
void generateWidgetsModule() {
  generateCoreFolder();
  
  final widgetsDir = Directory('lib/core/widgets');
  widgetsDir.createSync(recursive: true);
  
  // Create app_shimmer.dart
  final shimmerFile = File('lib/core/widgets/app_shimmer.dart');
  shimmerFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey.shade300,
      highlightColor: highlightColor ?? Colors.grey.shade100,
      duration: duration,
      child: child,
    );
  }
}

class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ShimmerText extends StatelessWidget {
  final String? text;
  final TextStyle? style;
  final double? width;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerText({
    super.key,
    this.text,
    this.style,
    this.width,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: text != null
          ? Text(
              text!,
              style: style,
              maxLines: 1,
            )
          : ShimmerContainer(
              height: style?.fontSize ?? 16,
              width: width ?? 100,
            ),
    );
  }
}
''');
  print('Created: lib/core/widgets/app_shimmer.dart');

  // Create widgets_export.dart
  final widgetsExportFile = File('lib/core/widgets/widgets_export.dart');
  widgetsExportFile.writeAsStringSync('''
// Widgets exports
export 'app_shimmer.dart';
''');
  print('Created: lib/core/widgets/widgets_export.dart');
}

/// Generate localization module
void generateLocalizationModule() {
  generateCoreFolder();
  
  final l10nDir = Directory('lib/core/l10n');
  l10nDir.createSync(recursive: true);
  
  // Create app_en.arb
  final enArbFile = File('lib/core/l10n/app_en.arb');
  enArbFile.writeAsStringSync('''
{
  "@@locale": "en",
  "appTitle": "My App",
  "@appTitle": {
    "description": "The title of the application"
  },
  
  "welcome": "Welcome",
  "@welcome": {
    "description": "Welcome message"
  },
  
  "login": "Login",
  "@login": {
    "description": "Login button text"
  },
  
  "register": "Register",
  "@register": {
    "description": "Register button text"
  },
  
  "email": "Email",
  "@email": {
    "description": "Email field label"
  },
  
  "password": "Password",
  "@password": {
    "description": "Password field label"
  },
  
  "home": "Home",
  "@home": {
    "description": "Home page title"
  },
  
  "profile": "Profile",
  "@profile": {
    "description": "Profile page title"
  },
  
  "settings": "Settings",
  "@settings": {
    "description": "Settings page title"
  }
}
''');
  print('Created: lib/core/l10n/app_en.arb');

  // Create app_ur.arb (Urdu)
  final urArbFile = File('lib/core/l10n/app_ur.arb');
  urArbFile.writeAsStringSync('''
{
  "@@locale": "ur",
  "appTitle": "میری ایپ",
  "@appTitle": {
    "description": "ایپلی کیشن کا عنوان"
  },
  
  "welcome": "خوش آمدید",
  "@welcome": {
    "description": "خوش آمدید کا پیغام"
  },
  
  "login": "لاگ ان کریں",
  "@login": {
    "description": "لاگ ان بٹن کا متن"
  },
  
  "register": "رجسٹر کریں",
  "@register": {
    "description": "رجسٹر بٹن کا متن"
  },
  
  "email": "ای میل",
  "@email": {
    "description": "ای میل فیلڈ لیبل"
  },
  
  "password": "پاس ورڈ",
  "@password": {
    "description": "پاس ورڈ فیلڈ لیبل"
  },
  
  "home": "ہوم",
  "@home": {
    "description": "ہوم پیج کا عنوان"
  },
  
  "profile": "پروفائل",
  "@profile": {
    "description": "پروفائل پیج کا عنوان"
  },
  
  "settings": "ترتیبات",
  "@settings": {
    "description": "ترتیبات پیج کا عنوان"
  }
}
''');
  print('Created: lib/core/l10n/app_ur.arb');

  // Create localization service
  final localizationDir = Directory('lib/core/localization');
  localizationDir.createSync(recursive: true);
  
  final localizationServiceFile = File('lib/core/localization/app_localization_service.dart');
  localizationServiceFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';

class AppLocalizationService {
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ur'), // Urdu
  ];

  static const Locale fallbackLocale = Locale('en');

  static const LocalizationsDelegate<AppLocalizations> localizationDelegate =
      AppLocalizations.delegate;

  static bool isLocaleSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }

  static Locale getLocale(String languageCode) {
    for (var locale in supportedLocales) {
      if (locale.languageCode == languageCode) {
        return locale;
      }
    }
    return fallbackLocale;
  }

  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ur':
        return 'اردو';
      default:
        return locale.languageCode.toUpperCase();
    }
  }
}
''');
  print('Created: lib/core/localization/app_localization_service.dart');
}

/// Generate config module
void generateConfigModule() {
  generateCoreFolder();
  
  final configDir = Directory('lib/core/config');
  configDir.createSync(recursive: true);
  
  // Create app_config.dart
  final appConfigFile = File('lib/core/config/app_config.dart');
  appConfigFile.writeAsStringSync('''
import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment
  static const String environment = kDebugMode ? 'development' : 'production';
  
  // API Configuration
  static const String apiBaseUrl = kDebugMode 
      ? 'https://api.example.com/dev'
      : 'https://api.example.com/prod';
      
  static const int apiTimeout = 30;
  static const bool enableApiLogging = kDebugMode;

  // Feature flags
  static const bool enableAnalytics = !kDebugMode;
  static const bool enableCrashlytics = !kDebugMode;
  static const bool enablePerformanceMonitoring = !kDebugMode;

  // App Configuration
  static const String appName = 'My App';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Security
  static const bool enableEncryption = true;
  static const bool enableBiometricAuth = true;

  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // UI Configuration
  static const bool enableAnimations = true;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Logging
  static const bool enableConsoleLogging = kDebugMode;
  static const bool enableFileLogging = kDebugMode;

  // Network Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 50;

  // Social Login
  static const bool enableGoogleLogin = true;
  static const bool enableFacebookLogin = false;
  static const bool enableAppleLogin = true;

  // Storage
  static const bool enableCloudStorage = true;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Notifications
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;

  // Rate Limiting
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
}
''');
  print('Created: lib/core/config/app_config.dart');

  // Create flavor_setup_helper.dart
  final flavorHelperFile = File('lib/core/config/flavor_setup_helper.dart');
  flavorHelperFile.writeAsStringSync('''
import 'package:flutter/foundation.dart';

enum AppFlavor {
  development,
  staging,
  production,
}

class FlavorConfig {
  final AppFlavor flavor;
  final String name;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableAnalytics;

  FlavorConfig({
    required this.flavor,
    required this.name,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.enableAnalytics,
  });

  static AppFlavor get currentFlavor {
    // In a real app, you'd get this from environment variables or build configuration
    if (kDebugMode) return AppFlavor.development;
    return AppFlavor.production;
  }

  static FlavorConfig get currentConfig {
    switch (currentFlavor) {
      case AppFlavor.development:
        return FlavorConfig(
          flavor: AppFlavor.development,
          name: 'Development',
          apiBaseUrl: 'https://api.example.com/dev',
          enableLogging: true,
          enableAnalytics: false,
        );
      case AppFlavor.staging:
        return FlavorConfig(
          flavor: AppFlavor.staging,
          name: 'Staging',
          apiBaseUrl: 'https://api.example.com/staging',
          enableLogging: true,
          enableAnalytics: true,
        );
      case AppFlavor.production:
        return FlavorConfig(
          flavor: AppFlavor.production,
          name: 'Production',
          apiBaseUrl: 'https://api.example.com/prod',
          enableLogging: false,
          enableAnalytics: true,
        );
    }
  }

  bool get isDevelopment => flavor == AppFlavor.development;
  bool get isStaging => flavor == AppFlavor.staging;
  bool get isProduction => flavor == AppFlavor.production;
}

class FlavorSetupHelper {
  static void setupFlavor() {
    // Setup flavor-specific configurations
    final config = FlavorConfig.currentConfig;
    
    if (config.enableLogging) {
      // Enable debug logging
      debugPrint('Flavor: \${config.name}');
      debugPrint('API Base URL: \${config.apiBaseUrl}');
    }
  }
}
''');
  print('Created: lib/core/config/flavor_setup_helper.dart');
}

/// Generate feature with clean architecture structure
void generateFeature(String featureName) {
  // Normalize feature name (convert to lowercase and remove special characters)
  final normalizedFeatureName = featureName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  final pascalCaseFeatureName = _toPascalCase(normalizedFeatureName);
  
  final featureDir = Directory('lib/features/$normalizedFeatureName');
  featureDir.createSync(recursive: true);
  
  print('Creating feature: $normalizedFeatureName');
  
  // Create directory structure
  final directories = [
    'data/data_sources',
    'data/models',
    'data/mappers',
    'data/repositories',
    'domain/entities',
    'domain/repositories',
    'domain/use_cases',
    'presentation/manager',
    'presentation/screens',
    'presentation/widgets',
  ];
  
  for (final dir in directories) {
    final fullDir = Directory('lib/features/$normalizedFeatureName/$dir');
    fullDir.createSync(recursive: true);
  }
  
  // Create entity
  final entityFile = File('lib/features/$normalizedFeatureName/domain/entities/${normalizedFeatureName}_entity.dart');
  entityFile.writeAsStringSync('''
import 'package:equatable/equatable.dart';

class ${pascalCaseFeatureName}Entity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const ${pascalCaseFeatureName}Entity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, createdAt];
}
''');
  print('Created: lib/features/$normalizedFeatureName/domain/entities/${normalizedFeatureName}_entity.dart');

  // Create model
  final modelFile = File('lib/features/$normalizedFeatureName/data/models/${normalizedFeatureName}_model.dart');
  modelFile.writeAsStringSync('''
import '../../domain/entities/${normalizedFeatureName}_entity.dart';

class ${pascalCaseFeatureName}Model extends ${pascalCaseFeatureName}Entity {
  const ${pascalCaseFeatureName}Model({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  factory ${pascalCaseFeatureName}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalCaseFeatureName}Model(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
''');
  print('Created: lib/features/$normalizedFeatureName/data/models/${normalizedFeatureName}_model.dart');

  // Create remote data source
  final remoteDataSourceFile = File('lib/features/$normalizedFeatureName/data/data_sources/${normalizedFeatureName}_remote_data_source.dart');
  remoteDataSourceFile.writeAsStringSync('''
import '../models/${normalizedFeatureName}_model.dart';

abstract class ${pascalCaseFeatureName}RemoteDataSource {
  Future<${pascalCaseFeatureName}Model> getById(String id);
  Future<List<${pascalCaseFeatureName}Model>> getAll({int? page, int? limit});
  Future<${pascalCaseFeatureName}Model> create(Map<String, dynamic> data);
  Future<${pascalCaseFeatureName}Model> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
}
''');
  print('Created: lib/features/$normalizedFeatureName/data/data_sources/${normalizedFeatureName}_remote_data_source.dart');

  // Create remote data source implementation
  final remoteDataSourceImplFile = File('lib/features/$normalizedFeatureName/data/data_sources/${normalizedFeatureName}_remote_data_source_impl.dart');
  remoteDataSourceImplFile.writeAsStringSync('''
import '../../../../core/network/api_client.dart';
import '../../../../core/network/app_urls.dart';
import '../models/${normalizedFeatureName}_model.dart';
import '${normalizedFeatureName}_remote_data_source.dart';

class ${pascalCaseFeatureName}RemoteDataSourceImpl implements ${pascalCaseFeatureName}RemoteDataSource {
  final ApiClient _apiClient;

  ${pascalCaseFeatureName}RemoteDataSourceImpl(this._apiClient);

  @override
  Future<${pascalCaseFeatureName}Model> getById(String id) async {
    final response = await _apiClient.get('${normalizedFeatureName}s/\$id');
    return ${pascalCaseFeatureName}Model.fromJson(response);
  }

  @override
  Future<List<${pascalCaseFeatureName}Model>> getAll({int? page, int? limit}) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _apiClient.get('${normalizedFeatureName}s', queryParameters: queryParams);
    final List<dynamic> data = response['data'] ?? response;
    return data.map((json) => ${pascalCaseFeatureName}Model.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<${pascalCaseFeatureName}Model> create(Map<String, dynamic> data) async {
    final response = await _apiClient.post('${normalizedFeatureName}s', data: data);
    return ${pascalCaseFeatureName}Model.fromJson(response);
  }

  @override
  Future<${pascalCaseFeatureName}Model> update(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('${normalizedFeatureName}s/\$id', data: data);
    return ${pascalCaseFeatureName}Model.fromJson(response);
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('${normalizedFeatureName}s/\$id');
  }
}
''');
  print('Created: lib/features/$normalizedFeatureName/data/data_sources/${normalizedFeatureName}_remote_data_source_impl.dart');

  // Create repository interface
  final repositoryFile = File('lib/features/$normalizedFeatureName/domain/repositories/${normalizedFeatureName}_repository.dart');
  repositoryFile.writeAsStringSync('''
import '../entities/${normalizedFeatureName}_entity.dart';

abstract class ${pascalCaseFeatureName}Repository {
  Future<${pascalCaseFeatureName}Entity> getById(String id);
  Future<List<${pascalCaseFeatureName}Entity>> getAll({int? page, int? limit});
  Future<${pascalCaseFeatureName}Entity> create(Map<String, dynamic> data);
  Future<${pascalCaseFeatureName}Entity> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
}
''');
  print('Created: lib/features/$normalizedFeatureName/domain/repositories/${normalizedFeatureName}_repository.dart');

  // Create repository implementation
  final repositoryImplFile = File('lib/features/$normalizedFeatureName/data/repositories/${normalizedFeatureName}_repository_impl.dart');
  repositoryImplFile.writeAsStringSync('''
import '../../domain/entities/${normalizedFeatureName}_entity.dart';
import '../../domain/repositories/${normalizedFeatureName}_repository.dart';
import '../data_sources/${normalizedFeatureName}_remote_data_source.dart';
import '../models/${normalizedFeatureName}_model.dart';

class ${pascalCaseFeatureName}RepositoryImpl implements ${pascalCaseFeatureName}Repository {
  final ${pascalCaseFeatureName}RemoteDataSource _remoteDataSource;

  ${pascalCaseFeatureName}RepositoryImpl(this._remoteDataSource);

  @override
  Future<${pascalCaseFeatureName}Entity> getById(String id) async {
    final model = await _remoteDataSource.getById(id);
    return model; // Model extends Entity, so we can return it directly
  }

  @override
  Future<List<${pascalCaseFeatureName}Entity>> getAll({int? page, int? limit}) async {
    final models = await _remoteDataSource.getAll(page: page, limit: limit);
    return models.cast<${pascalCaseFeatureName}Entity>();
  }

  @override
  Future<${pascalCaseFeatureName}Entity> create(Map<String, dynamic> data) async {
    final model = await _remoteDataSource.create(data);
    return model;
  }

  @override
  Future<${pascalCaseFeatureName}Entity> update(String id, Map<String, dynamic> data) async {
    final model = await _remoteDataSource.update(id, data);
    return model;
  }

  @override
  Future<void> delete(String id) async {
    await _remoteDataSource.delete(id);
  }
}
''');
  print('Created: lib/features/$normalizedFeatureName/data/repositories/${normalizedFeatureName}_repository_impl.dart');

  // Create use cases
  final useCases = ['get', 'get_all', 'create', 'update', 'delete'];
  for (final useCase in useCases) {
    final useCaseFile = File('lib/features/$normalizedFeatureName/domain/use_cases/${useCase}_${normalizedFeatureName}_use_case.dart');
    
    if (useCase == 'get') {
      useCaseFile.writeAsStringSync('''
import '../../../../core/usecase/base_use_case.dart';
import '../entities/${normalizedFeatureName}_entity.dart';
import '../repositories/${normalizedFeatureName}_repository.dart';

class Get${pascalCaseFeatureName}UseCase extends UseCase<${pascalCaseFeatureName}Entity, Get${pascalCaseFeatureName}Params> {
  final ${pascalCaseFeatureName}Repository _repository;

  Get${pascalCaseFeatureName}UseCase(this._repository);

  @override
  Future<${pascalCaseFeatureName}Entity> call(Get${pascalCaseFeatureName}Params params) async {
    return await _repository.getById(params.id);
  }
}

class Get${pascalCaseFeatureName}Params extends Equatable {
  final String id;

  const Get${pascalCaseFeatureName}Params({required this.id});

  @override
  List<Object?> get props => [id];
}
''');
    } else if (useCase == 'get_all') {
      useCaseFile.writeAsStringSync('''
import '../../../../core/usecase/base_use_case.dart';
import '../entities/${normalizedFeatureName}_entity.dart';
import '../repositories/${normalizedFeatureName}_repository.dart';

class GetAll${pascalCaseFeatureName}sUseCase extends UseCase<List<${pascalCaseFeatureName}Entity>, GetAll${pascalCaseFeatureName}sParams> {
  final ${pascalCaseFeatureName}Repository _repository;

  GetAll${pascalCaseFeatureName}sUseCase(this._repository);

  @override
  Future<List<${pascalCaseFeatureName}Entity>> call(GetAll${pascalCaseFeatureName}sParams params) async {
    return await _repository.getAll(page: params.page, limit: params.limit);
  }
}

class GetAll${pascalCaseFeatureName}sParams extends Equatable {
  final int? page;
  final int? limit;

  const GetAll${pascalCaseFeatureName}sParams({this.page, this.limit});

  @override
  List<Object?> get props => [page, limit];
}
''');
    } else if (useCase == 'create') {
      useCaseFile.writeAsStringSync('''
import '../../../../core/usecase/base_use_case.dart';
import '../entities/${normalizedFeatureName}_entity.dart';
import '../repositories/${normalizedFeatureName}_repository.dart';

class Create${pascalCaseFeatureName}UseCase extends UseCase<${pascalCaseFeatureName}Entity, Create${pascalCaseFeatureName}Params> {
  final ${pascalCaseFeatureName}Repository _repository;

  Create${pascalCaseFeatureName}UseCase(this._repository);

  @override
  Future<${pascalCaseFeatureName}Entity> call(Create${pascalCaseFeatureName}Params params) async {
    return await _repository.create(params.data);
  }
}

class Create${pascalCaseFeatureName}Params extends Equatable {
  final Map<String, dynamic> data;

  const Create${pascalCaseFeatureName}Params({required this.data});

  @override
  List<Object?> get props => [data];
}
''');
    } else if (useCase == 'update') {
      useCaseFile.writeAsStringSync('''
import '../../../../core/usecase/base_use_case.dart';
import '../entities/${normalizedFeatureName}_entity.dart';
import '../repositories/${normalizedFeatureName}_repository.dart';

class Update${pascalCaseFeatureName}UseCase extends UseCase<${pascalCaseFeatureName}Entity, Update${pascalCaseFeatureName}Params> {
  final ${pascalCaseFeatureName}Repository _repository;

  Update${pascalCaseFeatureName}UseCase(this._repository);

  @override
  Future<${pascalCaseFeatureName}Entity> call(Update${pascalCaseFeatureName}Params params) async {
    return await _repository.update(params.id, params.data);
  }
}

class Update${pascalCaseFeatureName}Params extends Equatable {
  final String id;
  final Map<String, dynamic> data;

  const Update${pascalCaseFeatureName}Params({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}
''');
    } else if (useCase == 'delete') {
      useCaseFile.writeAsStringSync('''
import '../../../../core/usecase/base_use_case.dart';
import '../repositories/${normalizedFeatureName}_repository.dart';

class Delete${pascalCaseFeatureName}UseCase extends UseCase<void, Delete${pascalCaseFeatureName}Params> {
  final ${pascalCaseFeatureName}Repository _repository;

  Delete${pascalCaseFeatureName}UseCase(this._repository);

  @override
  Future<void> call(Delete${pascalCaseFeatureName}Params params) async {
    await _repository.delete(params.id);
  }
}

class Delete${pascalCaseFeatureName}Params extends Equatable {
  final String id;

  const Delete${pascalCaseFeatureName}Params({required this.id});

  @override
  List<Object?> get props => [id];
}
''');
    }
    print('Created: lib/features/$normalizedFeatureName/domain/use_cases/${useCase}_${normalizedFeatureName}_use_case.dart');
  }

  // Create cubit
  final cubitFile = File('lib/features/$normalizedFeatureName/presentation/manager/${normalizedFeatureName}_cubit.dart');
  cubitFile.writeAsStringSync('''
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/${normalizedFeatureName}_entity.dart';
import '../../domain/use_cases/get_${normalizedFeatureName}_use_case.dart';
import '../../domain/use_cases/get_all_${normalizedFeatureName}s_use_case.dart';
import '../../domain/use_cases/create_${normalizedFeatureName}_use_case.dart';
import '../../domain/use_cases/update_${normalizedFeatureName}_use_case.dart';
import '../../domain/use_cases/delete_${normalizedFeatureName}_use_case.dart';
import '${normalizedFeatureName}_state.dart';

class ${pascalCaseFeatureName}Cubit extends Cubit<${pascalCaseFeatureName}State> {
  final Get${pascalCaseFeatureName}UseCase _get${pascalCaseFeatureName}UseCase;
  final GetAll${pascalCaseFeatureName}sUseCase _getAll${pascalCaseFeatureName}sUseCase;
  final Create${pascalCaseFeatureName}UseCase _create${pascalCaseFeatureName}UseCase;
  final Update${pascalCaseFeatureName}UseCase _update${pascalCaseFeatureName}UseCase;
  final Delete${pascalCaseFeatureName}UseCase _delete${pascalCaseFeatureName}UseCase;

  ${pascalCaseFeatureName}Cubit({
    required Get${pascalCaseFeatureName}UseCase get${pascalCaseFeatureName}UseCase,
    required GetAll${pascalCaseFeatureName}sUseCase getAll${pascalCaseFeatureName}sUseCase,
    required Create${pascalCaseFeatureName}UseCase create${pascalCaseFeatureName}UseCase,
    required Update${pascalCaseFeatureName}UseCase update${pascalCaseFeatureName}UseCase,
    required Delete${pascalCaseFeatureName}UseCase delete${pascalCaseFeatureName}UseCase,
  })  : _get${pascalCaseFeatureName}UseCase = get${pascalCaseFeatureName}UseCase,
        _getAll${pascalCaseFeatureName}sUseCase = getAll${pascalCaseFeatureName}sUseCase,
        _create${pascalCaseFeatureName}UseCase = create${pascalCaseFeatureName}UseCase,
        _update${pascalCaseFeatureName}UseCase = update${pascalCaseFeatureName}UseCase,
        _delete${pascalCaseFeatureName}UseCase = delete${pascalCaseFeatureName}UseCase,
        super(${pascalCaseFeatureName}State.initial());

  // Get all items
  Future<void> getAll({int? page, int? limit}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _getAll${pascalCaseFeatureName}sUseCase(GetAll${pascalCaseFeatureName}sParams(page: page, limit: limit));
      emit(state.copyWith(
        isLoading: false,
        items: items,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Get single item
  Future<void> getById(String id) async {
    emit(state.copyWith(isLoading: true));
    try {
      final item = await _get${pascalCaseFeatureName}UseCase(Get${pascalCaseFeatureName}Params(id: id));
      emit(state.copyWith(
        isLoading: false,
        selectedItem: item,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Create item
  Future<void> create(Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true));
    try {
      final item = await _create${pascalCaseFeatureName}UseCase(Create${pascalCaseFeatureName}Params(data: data));
      final updatedItems = [...state.items, item];
      emit(state.copyWith(
        isLoading: false,
        items: updatedItems,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Update item
  Future<void> update(String id, Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true));
    try {
      final updatedItem = await _update${pascalCaseFeatureName}UseCase(Update${pascalCaseFeatureName}Params(id: id, data: data));
      final updatedItems = state.items.map((item) => item.id == id ? updatedItem : item).toList();
      emit(state.copyWith(
        isLoading: false,
        items: updatedItems,
        selectedItem: updatedItem,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Delete item
  Future<void> delete(String id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _delete${pascalCaseFeatureName}UseCase(Delete${pascalCaseFeatureName}Params(id: id));
      final updatedItems = state.items.where((item) => item.id != id).toList();
      emit(state.copyWith(
        isLoading: false,
        items: updatedItems,
        selectedItem: state.selectedItem?.id == id ? null : state.selectedItem,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Clear error
  void clearError() {
    emit(state.copyWith(error: null));
  }

  // Clear selected item
  void clearSelectedItem() {
    emit(state.copyWith(selectedItem: null));
  }
}
''');
  print('Created: lib/features/$normalizedFeatureName/presentation/manager/${normalizedFeatureName}_cubit.dart');

  // Create state
  final stateFile = File('lib/features/$normalizedFeatureName/presentation/manager/${normalizedFeatureName}_state.dart');
  stateFile.writeAsStringSync('''
import 'package:equatable/equatable.dart';
import '../../domain/entities/${normalizedFeatureName}_entity.dart';

class ${pascalCaseFeatureName}State extends Equatable {
  final List<${pascalCaseFeatureName}Entity> items;
  final ${pascalCaseFeatureName}Entity? selectedItem;
  final bool isLoading;
  final String? error;

  const ${pascalCaseFeatureName}State({
    this.items = const [],
    this.selectedItem,
    this.isLoading = false,
    this.error,
  });

  factory ${pascalCaseFeatureName}State.initial() {
    return const ${pascalCaseFeatureName}State();
  }

  ${pascalCaseFeatureName}State copyWith({
    List<${pascalCaseFeatureName}Entity>? items,
    ${pascalCaseFeatureName}Entity? selectedItem,
    bool? isLoading,
    String? error,
  }) {
    return ${pascalCaseFeatureName}State(
      items: items ?? this.items,
      selectedItem: selectedItem ?? this.selectedItem,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [items, selectedItem, isLoading, error];
}
''');
  print('Created: lib/features/$normalizedFeatureName/presentation/manager/${normalizedFeatureName}_state.dart');

  // Create screen
  final screenFile = File('lib/features/$normalizedFeatureName/presentation/screens/${normalizedFeatureName}_screen.dart');
  screenFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../manager/${normalizedFeatureName}_cubit.dart';

class ${pascalCaseFeatureName}Screen extends StatelessWidget {
  const ${pascalCaseFeatureName}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ${pascalCaseFeatureName}Cubit(
        get${pascalCaseFeatureName}UseCase: context.read(),
        getAll${pascalCaseFeatureName}sUseCase: context.read(),
        create${pascalCaseFeatureName}UseCase: context.read(),
        update${pascalCaseFeatureName}UseCase: context.read(),
        delete${pascalCaseFeatureName}UseCase: context.read(),
      ),
      child: const ${pascalCaseFeatureName}View(),
    );
  }
}

class ${pascalCaseFeatureName}View extends StatefulWidget {
  const ${pascalCaseFeatureName}View({super.key});

  @override
  State<${pascalCaseFeatureName}View> createState() => _${pascalCaseFeatureName}ViewState();
}

class _${pascalCaseFeatureName}ViewState extends State<${pascalCaseFeatureName}View> {
  late final ${pascalCaseFeatureName}Cubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<${pascalCaseFeatureName}Cubit>();
    _cubit.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${pascalCaseFeatureName}'),
      ),
      body: BlocBuilder<${pascalCaseFeatureName}Cubit, ${pascalCaseFeatureName}State>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: \${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cubit.getAll(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.items.isEmpty) {
            return const Center(
              child: Text('No ${normalizedFeatureName}s found'),
            );
          }

          return ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.createdAt.toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Navigate to edit screen
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _cubit.delete(item.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
''');
  print('Created: lib/features/$normalizedFeatureName/presentation/screens/${normalizedFeatureName}_screen.dart');

  // Create dependency injection file
  final injectionFile = File('lib/features/$normalizedFeatureName/${normalizedFeatureName}_injection.dart');
  injectionFile.writeAsStringSync('''
import '../../../../core/di/dependency_injection.dart';
import '../data/data_sources/${normalizedFeatureName}_remote_data_source.dart';
import '../data/data_sources/${normalizedFeatureName}_remote_data_source_impl.dart';
import '../data/repositories/${normalizedFeatureName}_repository_impl.dart';
import '../domain/repositories/${normalizedFeatureName}_repository.dart';
import '../domain/use_cases/get_${normalizedFeatureName}_use_case.dart';
import '../domain/use_cases/get_all_${normalizedFeatureName}s_use_case.dart';
import '../domain/use_cases/create_${normalizedFeatureName}_use_case.dart';
import '../domain/use_cases/update_${normalizedFeatureName}_use_case.dart';
import '../domain/use_cases/delete_${normalizedFeatureName}_use_case.dart';

void init${pascalCaseFeatureName}Injector() {
  // Register Remote Data Source
  sl.registerLazySingleton<${pascalCaseFeatureName}RemoteDataSource>(
    () => ${pascalCaseFeatureName}RemoteDataSourceImpl(sl()),
  );

  // Register Repository
  sl.registerLazySingleton<${pascalCaseFeatureName}Repository>(
    () => ${pascalCaseFeatureName}RepositoryImpl(sl<${pascalCaseFeatureName}RemoteDataSource>()),
  );

  // Register Use Cases
  sl.registerLazySingleton<Get${pascalCaseFeatureName}UseCase>(
    () => Get${pascalCaseFeatureName}UseCase(sl<${pascalCaseFeatureName}Repository>()),
  );

  sl.registerLazySingleton<GetAll${pascalCaseFeatureName}sUseCase>(
    () => GetAll${pascalCaseFeatureName}sUseCase(sl<${pascalCaseFeatureName}Repository>()),
  );

  sl.registerLazySingleton<Create${pascalCaseFeatureName}UseCase>(
    () => Create${pascalCaseFeatureName}UseCase(sl<${pascalCaseFeatureName}Repository>()),
  );

  sl.registerLazySingleton<Update${pascalCaseFeatureName}UseCase>(
    () => Update${pascalCaseFeatureName}UseCase(sl<${pascalCaseFeatureName}Repository>()),
  );

  sl.registerLazySingleton<Delete${pascalCaseFeatureName}UseCase>(
    () => Delete${pascalCaseFeatureName}UseCase(sl<${pascalCaseFeatureName}Repository>()),
  );
}
''');
  print('Created: lib/features/$normalizedFeatureName/${normalizedFeatureName}_injection.dart');

  print('✅ Feature "$normalizedFeatureName" created successfully!');
  print('📁 Location: lib/features/$normalizedFeatureName');
  print('🔧 Don\'t forget to add init${pascalCaseFeatureName}Injector() to your main DI file');
}

/// Convert string to PascalCase
// String _toPascalCase(String input) {
//   return input.split('_').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join('');
// }

/// Generate base use case file
void generateBaseUseCase() {
  generateCoreFolder();
  
  final useCaseDir = Directory('lib/core/use_case');
  useCaseDir.createSync(recursive: true);
  
  // Create base_use_case.dart
  final baseUseCaseFile = File('lib/core/use_case/base_use_case.dart');
  baseUseCaseFile.writeAsStringSync('''
import 'package:equatable/equatable.dart';

abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

abstract class UseCaseNoParams<Type> {
  Future<Type> call();
}

abstract class UseCaseWithParams<Type, Params> {
  Future<Type> call(Params params);
}

abstract class BaseUseCase<Type, Params> {
  Future<Type> call(Params params);
}

abstract class BaseParams extends Equatable {
  const BaseParams();
}
''');
  print('Created: lib/core/use_case/base_use_case.dart');
}

/// Update flutter section with proper configuration
void _updateFlutterSection(YamlEditor yamlEditor, Map pubspecMap) {
  // Add assets
  const assetsPaths = [
    'assets/img/',
    'assets/fonts/',
  ];

  if (pubspecMap.containsKey('flutter')) {
    final flutterSection = pubspecMap['flutter'] as Map;
    
    // Update assets
    if (flutterSection.containsKey('assets')) {
      final existingAssets = List<String>.from(flutterSection['assets']);
      for (var path in assetsPaths) {
        if (!existingAssets.contains(path)) {
          existingAssets.add(path);
        }
      }
      yamlEditor.update(['flutter', 'assets'], existingAssets);
    } else {
      yamlEditor.update(['flutter', 'assets'], assetsPaths);
    }

    // Ensure generate: true
    yamlEditor.update(['flutter', 'generate'], true);
    
    // Ensure uses-material-design: true
    yamlEditor.update(['flutter', 'uses-material-design'], true);

  } else {
    yamlEditor.update(['flutter'], {
      'generate': true,
      'uses-material-design': true,
      'assets': assetsPaths,
    });
  }

  // Add fonts section if not exists
  if (!pubspecMap.containsKey('fonts') || 
      (pubspecMap.containsKey('flutter') && !(pubspecMap['flutter'] as Map).containsKey('fonts'))) {
    yamlEditor.update(['flutter', 'fonts'], [
      {
        'family': 'MuktaMahee',
        'fonts': [
          {'asset': 'assets/fonts/MuktaMahee-Light.ttf', 'weight': 300},
          {'asset': 'assets/fonts/MuktaMahee-Regular.ttf', 'weight': 400},
          {'asset': 'assets/fonts/MuktaMahee-Medium.ttf', 'weight': 500},
          {'asset': 'assets/fonts/MuktaMahee-SemiBold.ttf', 'weight': 600},
        ]
      }
    ]);
  }
}

