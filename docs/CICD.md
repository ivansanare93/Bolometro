# CI/CD Guide

Bolometro uses GitHub Actions for Continuous Integration and Continuous Deployment.

## Workflow Overview

The CI/CD pipeline is defined in `.github/workflows/flutter-ci.yml` and runs on:
- Push to `main` and `develop` branches
- Pull requests to `main` and `develop` branches

## Pipeline Stages

### 1. Test and Analyze

**Runs on**: `ubuntu-latest`

**Steps**:
1. **Checkout code** - Gets the latest code from the repository
2. **Setup Flutter** - Installs Flutter 3.8.1 stable
3. **Install dependencies** - Runs `flutter pub get`
4. **Verify formatting** - Checks code formatting (continues on error)
5. **Analyze code** - Runs `flutter analyze` to check for issues
6. **Run tests** - Executes all tests with coverage
7. **Upload coverage** - Sends coverage report to Codecov

### 2. Build Android

**Runs on**: `ubuntu-latest`  
**Depends on**: Test and Analyze job

**Steps**:
1. **Checkout code**
2. **Setup Flutter**
3. **Install dependencies**
4. **Build APK** - Creates release APK
5. **Upload artifact** - Stores APK for download

### 3. Build iOS

**Runs on**: `macos-latest`  
**Depends on**: Test and Analyze job

**Steps**:
1. **Checkout code**
2. **Setup Flutter**
3. **Install dependencies**
4. **Build iOS** - Creates iOS build without codesigning

## Configuration

### Flutter Version

Current version: `3.8.1`

To update:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.10.0' # Update version here
    channel: 'stable'
```

### Test Coverage

Coverage is automatically uploaded to Codecov. To view:
1. Go to your repository on GitHub
2. Check the Codecov badge in README
3. Click to view detailed coverage report

### Artifacts

Build artifacts are retained for 90 days by default and can be downloaded from the Actions tab.

## Local Development

### Before Pushing Code

Run these commands locally to catch issues early:

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Pre-commit Checks

Consider adding a pre-commit hook:

```bash
# Create .git/hooks/pre-commit
#!/bin/bash

echo "Running pre-commit checks..."

# Format check
if ! dart format --output=none --set-exit-if-changed .; then
    echo "Code formatting failed. Run: dart format ."
    exit 1
fi

# Analyze
if ! flutter analyze; then
    echo "Flutter analyze failed."
    exit 1
fi

# Tests
if ! flutter test; then
    echo "Tests failed."
    exit 1
fi

echo "All checks passed!"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Managing Build Failures

### Test Failures

1. Check the test logs in GitHub Actions
2. Fix the failing tests locally
3. Run `flutter test` to verify
4. Push the fix

### Build Failures

#### Android Build Issues

Common causes:
- Gradle version incompatibility
- SDK version mismatch
- Missing dependencies

Fix:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### iOS Build Issues

Common causes:
- CocoaPods issues
- Xcode version incompatibility
- Missing certificates (not applicable for CI)

Fix:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter build ios --no-codesign
```

### Analysis Issues

Flutter analyze shows warnings/errors:

1. Fix all errors before committing
2. Address warnings when possible
3. Use `// ignore: rule_name` sparingly for valid exceptions

```dart
// ignore: avoid_print
print('Debug message');
```

## Adding New Workflows

### Deploy Workflow Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
          
      - name: Build App Bundle
        run: flutter build appbundle --release
        
      - name: Deploy to Play Store
        # Add deployment steps here
```

### Scheduled Tests

Run tests nightly:

```yaml
name: Nightly Tests

on:
  schedule:
    - cron: '0 2 * * *' # Runs at 2 AM UTC daily

jobs:
  test:
    # Same as test job in flutter-ci.yml
```

## Secrets Management

### Adding Secrets

1. Go to Repository Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Add secret name and value

### Using Secrets

```yaml
- name: Step using secret
  env:
    SECRET_KEY: ${{ secrets.SECRET_KEY }}
  run: echo "Using secret"
```

### Common Secrets

For deployment, you might need:
- `ANDROID_KEYSTORE` - Base64 encoded keystore
- `KEYSTORE_PASSWORD` - Keystore password
- `KEY_PASSWORD` - Key password
- `APPLE_CERTIFICATE` - iOS certificate
- `PROVISIONING_PROFILE` - iOS provisioning profile

## Environment Variables

### Setting Environment Variables

```yaml
env:
  FLUTTER_VERSION: '3.8.1'
  
jobs:
  test:
    env:
      TEST_ENV: 'ci'
```

### Using in Scripts

```yaml
- name: Print environment
  run: |
    echo "Flutter version: $FLUTTER_VERSION"
    echo "Test environment: $TEST_ENV"
```

## Caching

### Caching Dependencies

Speed up builds by caching:

```yaml
- name: Cache pub dependencies
  uses: actions/cache@v3
  with:
    path: ${{ env.PUB_CACHE }}
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-pub-
```

### Caching Build Artifacts

```yaml
- name: Cache build artifacts
  uses: actions/cache@v3
  with:
    path: |
      build
      .dart_tool
    key: ${{ runner.os }}-build-${{ hashFiles('**/pubspec.lock') }}
```

## Status Badges

Add status badges to README:

```markdown
![Flutter CI](https://github.com/ivansanare93/Bolometro/workflows/Flutter%20CI/badge.svg)
[![codecov](https://codecov.io/gh/ivansanare93/Bolometro/branch/main/graph/badge.svg)](https://codecov.io/gh/ivansanare93/Bolometro)
```

## Monitoring

### GitHub Actions Dashboard

- View all workflow runs
- Download logs
- Re-run failed jobs
- Cancel running jobs

### Email Notifications

GitHub sends email notifications on:
- Workflow failures
- First success after failure

Configure in: Settings > Notifications

## Best Practices

1. **Keep workflows fast** - Use caching, parallel jobs
2. **Fail fast** - Run tests before builds
3. **Use matrix builds** - Test multiple Flutter versions/platforms
4. **Keep secrets secure** - Never log secrets
5. **Document workflows** - Add comments explaining complex steps
6. **Version lock** - Pin action versions for reproducibility
7. **Test locally first** - Don't rely on CI to catch basic errors

## Troubleshooting

### Workflow Not Triggering

- Check branch names in `on.push.branches`
- Verify workflow file is in `.github/workflows/`
- Ensure YAML syntax is valid

### Permission Errors

Add permissions to workflow:

```yaml
permissions:
  contents: read
  packages: write
```

### Timeout Issues

Increase timeout:

```yaml
jobs:
  test:
    timeout-minutes: 30 # Default is 360
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
