import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';


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
void createFoldersAndFiles() {
  final templateDir = Directory('template');
  final targetDir = Directory('lib');
createAsset();
  if (!templateDir.existsSync()) {
    print('Template directory not found!');
    return;
  }

  // Copy files and directories from template to the target directory
  templateDir.listSync(recursive: true).forEach((entity) {
    if (entity is Directory) {
      final relativePath = entity.path.replaceFirst(templateDir.path, '');
      final targetSubDir = Directory(targetDir.path + relativePath);
      if (!targetSubDir.existsSync()) {
        targetSubDir.createSync(recursive: true);
        print('Created directory: ${targetSubDir.path}');
      }
    } else if (entity is File) {
      final relativePath = entity.path.replaceFirst(templateDir.path, '');
      final targetFile = File(targetDir.path + relativePath);

      // Ensure target directory exists
      targetFile.parent.createSync(recursive: true);

      // Copy file as is
      entity.copySync(targetFile.path);
      print('Created file: ${targetFile.path}');
    }
  });
}

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
    'firebase_messaging': '^15.0.3',
    'flutter_bloc': '^8.1.2',
    'flutter_svg': '^2.0.10+1',
    'pinput': '^5.0.0',
    'carousel_slider_plus': '^7.0.0',
    'connectivity_plus': '^6.0.3',
    'permission_handler': '^11.3.1',
    'path_provider': '^2.0.11',
    'dio': '^5.5.0+1',
    'flutter_local_notifications': '^17.1.0',
    'share_plus': '^9.0.0',
    'dio_cache_interceptor': '^3.5.0',
    'flutter_quick_router': '^0.0.2',
    'country_picker': '^2.0.26',
    'flutter_localizations': 'sdk: flutter',
    'drop_down_search_field': '^1.0.4',
    'quick_router': '^1.0.1',
    'gif_view': '^0.4.3',
    'dotted_border': '^2.1.0',
    'syncfusion_flutter_datepicker': '^26.1.41',
    'flutter_animate': '^4.5.0',
    'google_fonts': 'any',
    'video_player': '^2.9.1',
    'google_maps_flutter': '^2.7.0',
    'lottie': '^3.1.2',
    'share_it': '^0.7.0',
    'flutter_contacts': '^1.1.9',
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
