# clean_architecture_cli

`clean_architecture_cli` is a Dart CLI tool designed to help developers create clean architecture folder structures and automatically update the `pubspec.yaml` file in Flutter projects.

## Features

- **Generate Folders**: Automatically generate the clean architecture folder structure for your Flutter project.
- **Update pubspec.yaml**: Automatically add predefined dependencies and asset paths to your `pubspec.yaml` file.

## Installation

To install `clean_architecture_cli`, add the following dependency to your `pubspec.yaml`:
##  Usage
You can use the CLI tool to generate folders and update the pubspec.yaml file with the following commands:

dart run my_clean_cli --create --update-pubspec


```yaml
dev_dependencies:
  my_clean_cli: ^1.0.0

