import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/services/analytics_service.dart';

/// Tests for AnalyticsService
void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    test('AnalyticsService should be a singleton', () {
      final instance1 = AnalyticsService();
      final instance2 = AnalyticsService();
      
      expect(instance1, equals(instance2));
    });

    test('getAnalyticsObserver should return an observer', () {
      final observer = analyticsService.getAnalyticsObserver();
      
      expect(observer, isNotNull);
    });

    // Note: Testing actual Firebase Analytics events would require mocking
    // These tests verify the service structure is correct
    test('analytics service methods should not throw', () {
      expect(() => analyticsService.logScreenView('test_screen'), returnsNormally);
      expect(() => analyticsService.logSessionCreated('training'), returnsNormally);
      expect(() => analyticsService.logGameCreated(150), returnsNormally);
      expect(() => analyticsService.logLogin('google'), returnsNormally);
    });
  });
}
