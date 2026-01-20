# My Clean CLI

A powerful Dart CLI tool for generating clean architecture Flutter projects with complete feature scaffolding, dependency injection setup, and project structure management.

## Features

- 🏗️ **Complete Clean Architecture Setup** - Generate full Flutter projects with clean architecture structure
- 🔧 **Feature Generation** - Create complete features with data, domain, and presentation layers
- 📦 **Dependency Management** - Automatically add clean architecture dependencies to pubspec.yaml
- 🔐 **Private Repository Support** - Work with private GitLab/GitHub repositories
- 🌐 **SSL Certificate Bypass** - Support for repositories with self-signed certificates
- 💉 **Dependency Injection** - Automatic GetIt setup for all generated features
- 📱 **BLoC/Cubit State Management** - Ready-to-use state management implementation

## Installation

### Global Installation
```bash
dart pub global activate my_clean_cli
```

### Local Installation
Add to your `pubspec.yaml`:
```yaml
dev_dependencies:
  my_clean_cli: ^1.0.9
```

Then run:
```bash
dart pub get
```

## Quick Start

### 1. Create a New Clean Architecture Project
```bash
# Create basic structure
dart run my_clean_cli --create

# Create with custom template from private repository
dart run my_clean_cli --create --repo="YOUR_PRIVATE_REPO_URL" --insecure
```

### 2. Generate a Complete Feature
```bash
# Generate a new feature with complete clean architecture
dart run my_clean_cli --feature="user_profile"

# Generate feature using private repository template
dart run my_clean_cli --feature="notifications" --repo="YOUR_PRIVATE_REPO_URL" --insecure
```

### 3. Update Dependencies
```bash
# Add clean architecture dependencies to existing project
dart run my_clean_cli --update-deps

# Alternative command
dart run my_clean_cli --update-pubspec
```

## Command Reference

### Core Commands

| Command | Description | Example |
|---------|-------------|---------|
| `--create` | Create basic project structure | `dart run my_clean_cli --create` |
| `--feature <name>` | Generate complete feature | `dart run my_clean_cli --feature="user_management"` |
| `--update-deps` | Add clean architecture dependencies | `dart run my_clean_cli --update-deps` |
| `--update-pubspec` | Update pubspec.yaml (legacy) | `dart run my_clean_cli --update-pubspec` |

### Core Module Generation

| Flag | Description | Example |
|------|-------------|---------|
| `--core-all` | Generate all core modules | `dart run my_clean_cli --core-all` |
| `--theme` | Generate theme module | `dart run my_clean_cli --theme` |
| `--network` | Generate network module | `dart run my_clean_cli --network` |
| `--storage` | Generate storage module | `dart run my_clean_cli --storage` |
| `--router` | Generate router module | `dart run my_clean_cli --router` |
| `--di` | Generate dependency injection module | `dart run my_clean_cli --di` |
| `--constants` | Generate constants module | `dart run my_clean_cli --constants` |
| `--utils` | Generate utils module | `dart run my_clean_cli --utils` |
| `--widgets` | Generate widgets module | `dart run my_clean_cli --widgets` |
| `--localization` | Generate localization module | `dart run my_clean_cli --localization` |
| `--config` | Generate config module | `dart run my_clean_cli --config` |

### Repository Options

| Option | Description | Example |
|--------|-------------|---------|
| `--repo <url>` | Custom repository URL | `--repo="https://github.com/user/repo/archive/refs/heads/main.zip"` |
| `--insecure` | Skip SSL certificate verification | `--insecure` |

## Private Repository Setup

### Using Personal Access Tokens

For private GitLab repositories, you can use Personal Access Tokens:

```bash
# Format with OAuth token
dart run my_clean_cli --feature="my_feature" --repo="https://oauth2:YOUR_TOKEN@gitlab.com/your-group/your-repo/-/archive/main/your-repo-main.zip" --insecure

# Format with private token as query parameter
dart run my_clean_cli --feature="my_feature" --repo="https://gitlab.com/your-group/your-repo/-/archive/main/your-repo-main.zip?private_token=YOUR_TOKEN" --insecure
```

### Using Deploy Tokens

For GitLab deploy tokens:
```bash
dart run my_clean_cli --feature="my_feature" --repo="https://deploy-token-username:deploy-token@gitlab.com/your-group/your-repo/-/archive/main/your-repo-main.zip" --insecure
```

### SSL Certificate Issues

If you encounter SSL certificate errors with private repositories:
```bash
# Add --insecure flag to bypass SSL verification
dart run my_clean_cli --create --repo="YOUR_PRIVATE_REPO_URL" --insecure
```

## Generated Feature Structure

When you generate a feature, the CLI creates a complete clean architecture structure:

```
lib/features/your_feature/
├── data/
│   ├── data_sources/
│   │   ├── feature_local_data_source.dart
│   │   ├── feature_local_data_source_impl.dart
│   │   ├── feature_remote_data_source.dart
│   │   └── feature_remote_data_source_impl.dart
│   ├── database/
│   │   └── tables/
│   │       └── feature_table.dart
│   ├── mappers/
│   │   └── feature_mapper.dart
│   ├── models/
│   │   ├── feature_model.dart
│   │   └── feature_response.dart
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── feature_entity.dart
│   │   └── feature_list.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   └── use_cases/
│       └── get_feature_use_case.dart
├── presentation/
│   ├── cubit/
│   │   ├── feature_cubit.dart
│   │   ├── feature_state.dart
│   │   └── feature_state.freezed.dart
│   ├── pages/
│   │   └── feature_page.dart
│   └── widgets/
│       ├── feature_card.dart
│       └── feature_list.dart
└── feature_injection.dart
```

## Dependencies Added

The CLI automatically adds these clean architecture dependencies:

### Main Dependencies
- `flutter_bloc` - State management
- `dio` - HTTP client
- `equatable` - Value equality
- `freezed_annotation` - Code generation
- `go_router` - Navigation
- `shared_preferences` - Local storage
- `encrypt` - Encryption
- `get_it` - Dependency injection
- `drift` - Database
- `sqlite3_flutter_libs` - SQLite support
- `path_provider` - Path utilities
- `connectivity_plus` - Network connectivity
- `cached_network_image` - Image caching
- `logger` - Logging

### Dev Dependencies
- `build_runner` - Code generation
- `freezed` - Code generation
- `drift_dev` - Database code generation
- `mockito` - Testing

## Examples

### Complete Project Setup
```bash
# 1. Create new Flutter project
flutter create my_app
cd my_app

# 2. Set up clean architecture
dart run my_clean_cli --create

# 3. Add dependencies
dart run my_clean_cli --update-deps

# 4. Generate features
dart run my_clean_cli --feature="user_authentication"
dart run my_clean_cli --feature="product_catalog"
dart run my_clean_cli --feature="shopping_cart"

# 5. Generate core modules
dart run my_clean_cli --core-all
```

### Working with Private Templates
```bash
# Using private GitLab repository
dart run my_clean_cli --create --repo="https://oauth2:glpat-yourtoken@gitlab.com/company/project-templates/-/archive/main/flutter-template-main.zip?private_token=glpat-yourtoken" --insecure

# Generate feature from private template
dart run my_clean_cli --feature="custom_feature" --repo="https://oauth2:glpat-yourtoken@gitlab.com/company/project-templates/-/archive/main/flutter-template-main.zip?private_token=glpat-yourtoken" --insecure
```

## Publishing to Pub.dev

### 1. Prepare for Publishing
```bash
# Navigate to your project directory
cd /path/to/your/my_clean_cli

# Run tests
dart test

# Analyze code
dart analyze

# Format code
dart format .

# Check pubspec.yaml for correct version and metadata
```

### 2. Dry Run (Recommended)
```bash
# Test publish without actually publishing
dart pub publish --dry-run
```

### 3. Publish to Pub.dev
```bash
# Publish to pub.dev
dart pub publish
```

### 4. Publishing Commands Summary
```bash
# Complete publishing workflow
dart test                    # Run tests
dart analyze                 # Analyze code
dart format .               # Format code
dart pub publish --dry-run   # Test publish
dart pub publish             # Actual publish
```

## Configuration

### Environment Variables
You can set these environment variables for convenience:

```bash
# Default repository URL
export CLEAN_ARCH_CLI_REPO="https://your-default-repo.com/template.zip"

# Default private token
export CLEAN_ARCH_CLI_TOKEN="your-private-token"
```

### Configuration File
Create `.clean_arch_cli.yaml` in your project root:

```yaml
default_repo: "https://your-default-repo.com/template.zip"
default_token: "your-private-token"
insecure_by_default: true
auto_update_deps: true
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Errors**
   ```bash
   # Add --insecure flag
   dart run my_clean_cli --create --repo="YOUR_URL" --insecure
   ```

2. **Private Repository Access**
   ```bash
   # Use personal access token
   dart run my_clean_cli --feature="my_feature" --repo="https://oauth2:TOKEN@gitlab.com/.../archive/main/repo-main.zip?private_token=TOKEN" --insecure
   ```

3. **Permission Denied**
   ```bash
   # Make sure dart is in your PATH
   export PATH="$PATH:/path/to/dart/bin"
   ```

4. **Feature Already Exists**
   ```bash
   # Remove existing feature first
   rm -rf lib/features/feature_name
   ```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/farooq958/clean_architecture_cli/issues)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.
