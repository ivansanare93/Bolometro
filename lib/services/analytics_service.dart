import 'package:firebase_analytics/firebase_analytics.dart';

/// Service for handling Firebase Analytics events and logging
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // Screen view events
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // Session events
  Future<void> logSessionCreated(String sessionType) async {
    await _analytics.logEvent(
      name: 'session_created',
      parameters: {'session_type': sessionType},
    );
  }

  Future<void> logSessionDeleted() async {
    await _analytics.logEvent(name: 'session_deleted');
  }

  Future<void> logSessionEdited() async {
    await _analytics.logEvent(name: 'session_edited');
  }

  // Game events
  Future<void> logGameCreated(int score) async {
    await _analytics.logEvent(
      name: 'game_created',
      parameters: {'score': score},
    );
  }

  Future<void> logGameDeleted() async {
    await _analytics.logEvent(name: 'game_deleted');
  }

  Future<void> logGameEdited() async {
    await _analytics.logEvent(name: 'game_edited');
  }

  // User actions
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignOut() async {
    await _analytics.logEvent(name: 'sign_out');
  }

  Future<void> logSync() async {
    await _analytics.logEvent(name: 'data_sync');
  }

  // Statistics events
  Future<void> logStatisticsViewed(String filterType) async {
    await _analytics.logEvent(
      name: 'statistics_viewed',
      parameters: {'filter_type': filterType},
    );
  }

  Future<void> logChartViewed(String chartType) async {
    await _analytics.logEvent(
      name: 'chart_viewed',
      parameters: {'chart_type': chartType},
    );
  }

  // Profile events
  Future<void> logProfileUpdated() async {
    await _analytics.logEvent(name: 'profile_updated');
  }

  Future<void> logAvatarChanged() async {
    await _analytics.logEvent(name: 'avatar_changed');
  }

  // Settings events
  Future<void> logThemeChanged(String theme) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme': theme},
    );
  }

  Future<void> logLanguageChanged(String language) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {'language': language},
    );
  }

  // Share events
  Future<void> logShare(String contentType) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: 'share_$contentType',
      method: 'app_share',
    );
  }

  // Set user properties
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
