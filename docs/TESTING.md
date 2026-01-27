# Testing Guide

This document describes the comprehensive testing strategy implemented for Bolometro.

## Test Coverage

### Unit Tests

#### Models
- `test/partida_model_test.dart` - Tests for Partida model
- `test/sesion_model_test.dart` - Tests for Sesion model

#### Providers
- `test/theme_provider_test.dart` - Tests for theme management
- `test/language_provider_test.dart` - Tests for language switching

#### Services
- `test/analytics_service_test.dart` - Tests for analytics service
- `test/data_repository_test.dart` - Tests for data repository (existing)
- `test/estadisticas_cache_test.dart` - Tests for statistics caching (existing)

#### Utils
- `test/app_constants_test.dart` - Tests for app constants (existing)
- `test/lazy_loading_test.dart` - Tests for lazy loading (existing)

### Widget Tests
- `test/skeleton_loaders_test.dart` - Tests for skeleton loader components

### Integration Tests
- `test/integration_test.dart` - End-to-end user flow tests

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/partida_model_test.dart
```

### Run with coverage
```bash
flutter test --coverage
```

### View coverage report
```bash
# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

## CI/CD Integration

Tests are automatically run in the CI/CD pipeline:
- On every pull request
- On pushes to main and develop branches
- Coverage reports are uploaded to Codecov

See `.github/workflows/flutter-ci.yml` for details.

## Writing New Tests

### Unit Test Example
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyClass', () {
    test('should do something', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

### Widget Test Example
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyWidget should display text', (WidgetTester tester) async {
    await tester.pumpWidget(MyWidget());
    expect(find.text('Hello'), findsOneWidget);
  });
}
```

## Test Best Practices

1. **Arrange-Act-Assert Pattern**: Structure tests clearly
2. **Test Names**: Use descriptive names that explain what is being tested
3. **Mock External Dependencies**: Use mocks for Firebase, network calls, etc.
4. **Test Edge Cases**: Not just happy paths
5. **Keep Tests Fast**: Avoid unnecessary delays
6. **Independent Tests**: Each test should be able to run independently

## Known Limitations

- Firebase services (Auth, Firestore, Analytics) require mocking for proper testing
- Some integration tests are commented out pending Firebase test configuration
- Widget tests for complex screens may require extensive mocking

## Future Improvements

- [ ] Add golden tests for UI consistency
- [ ] Increase coverage to 80%+
- [ ] Add performance tests
- [ ] Mock Firebase services for integration tests
- [ ] Add screenshot tests for different screen sizes
