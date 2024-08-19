
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// The main function of the CLI tool.
/// It parses the command-line arguments and calls the appropriate functions.
/// The CLI tool supports two commands: create and update-pubspec.
/// The create command downloads a template ZIP file from GitHub and extracts the contents.
/// The update-pubspec command adds predefined dependencies and assets to the pubspec.yaml file.
/// The predefined dependencies are defined in the function.
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('create', abbr: 'c', help: 'Create predefined folders and files')
    ..addFlag('update-pubspec', abbr: 'u', help: 'Update pubspec.yaml');

  final argResults = parser.parse(arguments);

  if (argResults['create'] == true) {
    createFoldersAndFiles();
  }

  if (argResults['update-pubspec'] == true) {
    updatePubspec();
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
Future<void> createFoldersAndFiles() async {
  final targetDir = Directory('lib/');
  createAsset();

  try {
    // Download the template ZIP file from GitHub
    final url = 'https://github.com/farooq958/cli_template/archive/refs/heads/master.zip';
    final response = await http.get(Uri.parse(url));
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);

    // Extract only the files and directories from lib/template/
    final templatePrefix = 'cli_template-master/lib/template/';

    for (final file in archive) {
      if (file.name.startsWith(templatePrefix)) {
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
  } catch (e) {
    print('Error while creating files: $e');
  }
}

/// updatePubspec function is used to add predefined dependencies and assets to the pubspec.yaml file
/// if they don't already exist.
/// It also creates the flutter section if it doesn't exist.
/// The predefined dependencies are defined in the function.
void updatePubspec() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('pubspec.yaml not found!');
    return;
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final yamlEditor = YamlEditor(pubspecContent);

  final pubspecMap = loadYaml(pubspecContent) as Map;

  // Define predefined dependencies
  const predefinedDependencies = {
    'intl': 'any',
    'flutter_gen': '^5.4.0',
    'cached_network_image': '^3.3.0',
    'http': '^1.1.0',
    'shared_preferences': '^2.0.18',
    'flutter_launcher_icons': '^0.13.1',
    'firebase_core': '^3.2.0',
    'firebase_auth': '^5.1.2',
    'firebase_messaging': '^15.0.4',
    'flutter_bloc': '^8.1.2',
    'flutter_svg': '^2.0.10+1',
    'carousel_slider_plus': '^7.0.0',
    'connectivity_plus': '^6.0.3',
    'permission_handler': '^11.3.1',
    'path_provider': '^2.0.11',
    'dio': '^5.5.0+1',
    'flutter_local_notifications': '^17.1.0',
    'share_plus': '^10.0.0',
    'dio_cache_interceptor': '^3.5.0',
    'flutter_quick_router': '^0.0.2',
    'country_picker': '^2.0.26',
    'flutter_localizations': 'sdk: flutter',
    'drop_down_search_field': '^1.0.4',
    'quick_router': '^1.0.1',
    'gif_view': '^0.4.3',
    'dotted_border': '^2.1.0',
    'flutter_animate': '^4.5.0',
    'google_fonts': 'any',
    'video_player': '^2.9.1',
    'lottie': '^3.1.2',
    'image_picker': '^0.8.4+4',
    'image_cropper': '^1.4.0',
    'grouped_list': 'any',
    'scrollable_positioned_list': '^0.3.8',
  };

  // Add or update dependencies
  if (pubspecMap.containsKey('dependencies')) {
    predefinedDependencies.forEach((package, version) {
      if (!pubspecMap['dependencies'].containsKey(package)) {
        yamlEditor.update(['dependencies', package], version);
        print('Added $package:$version to dependencies.');
      } else {
        print('$package is already in dependencies.');
      }
    });
  } else {
    yamlEditor.update(['dependencies'], predefinedDependencies);
    print('Added predefined dependencies to pubspec.yaml.');
  }

  // Add or update assets
  const assetsPaths = [
    'assets/icons/',
    'assets/images/',
    'assets/gifs/',
  ];

  if (pubspecMap.containsKey('flutter')) {
    final flutterSection = pubspecMap['flutter'] as Map;
    if (flutterSection.containsKey('assets')) {
      final existingAssets = List<String>.from(flutterSection['assets']);
      for (var path in assetsPaths) {
        if (!existingAssets.contains(path)) {
          existingAssets.add(path);
        }
      }
      yamlEditor.update(['flutter', 'assets'], existingAssets);
      print('Updated assets in pubspec.yaml.');
    } else {
      yamlEditor.update(['flutter', 'assets'], assetsPaths);
      print('Added assets to pubspec.yaml.');
    }
  } else {
    yamlEditor.update(['flutter'], {
      'assets': assetsPaths,
    });
    print('Added flutter section with assets to pubspec.yaml.');
  }

  // Write the updated content back to the file
  pubspecFile.writeAsStringSync(yamlEditor.toString());
  print('pubspec.yaml updated successfully.');
}

