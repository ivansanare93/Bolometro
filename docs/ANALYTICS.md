# Analytics Guide

Bolometro uses Firebase Analytics to track user behavior and app performance.

## Overview

The `AnalyticsService` provides a centralized way to log analytics events throughout the app.

## Setup

### 1. Firebase Configuration

Ensure Firebase is properly configured:
- `android/app/google-services.json` - Android configuration
- `ios/Runner/GoogleService-Info.plist` - iOS configuration

### 2. Enable Analytics in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Analytics
4. Enable Google Analytics

## Using Analytics Service

### Singleton Instance

```dart
import 'package:bolometro/services/analytics_service.dart';
import 'package:provider/provider.dart';

// Get instance via Provider
final analytics = Provider.of<AnalyticsService>(context, listen: false);

// Or use singleton directly
final analytics = AnalyticsService();
```

## Available Events

### Screen Views

Automatically tracked when using the analytics observer, or manually:

```dart
analytics.logScreenView('home_screen');
analytics.logScreenView('statistics_screen');
```

### Session Events

```dart
// When creating a new session
analytics.logSessionCreated('training'); // or 'competition'

// When editing a session
analytics.logSessionEdited();

// When deleting a session
analytics.logSessionDeleted();
```

### Game Events

```dart
// When creating a new game
analytics.logGameCreated(150); // Pass the score

// When editing a game
analytics.logGameEdited();

// When deleting a game
analytics.logGameDeleted();
```

### User Authentication

```dart
// When user logs in
analytics.logLogin('google'); // or other method

// When user signs out
analytics.logSignOut();

// Set user ID (called automatically on login)
analytics.setUserId('user123');
```

### Data Sync

```dart
// When syncing data with cloud
analytics.logSync();
```

### Statistics Events

```dart
// When viewing statistics page
analytics.logStatisticsViewed('all'); // or 'training', 'competition'

// When viewing a specific chart
analytics.logChartViewed('histogram');
analytics.logChartViewed('moving_average');
analytics.logChartViewed('heatmap');
```

### Profile Events

```dart
// When updating profile
analytics.logProfileUpdated();

// When changing avatar
analytics.logAvatarChanged();
```

### Settings Events

```dart
// When changing theme
analytics.logThemeChanged('dark'); // 'light', 'dark', 'system'

// When changing language
analytics.logLanguageChanged('en'); // 'es', 'en'
```

### Share Events

```dart
// When sharing content
analytics.logShare('session'); // or 'statistics', 'game'
```

### User Properties

```dart
// Set custom user properties
analytics.setUserProperty('preferred_hand', 'right');
analytics.setUserProperty('skill_level', 'intermediate');
```

## Implementation Examples

### Tracking Button Clicks

```dart
ElevatedButton(
  onPressed: () async {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    await analytics.logGameCreated(score);
    
    // Continue with your logic
    Navigator.push(...);
  },
  child: Text('Save Game'),
)
```

### Tracking Screen Navigation

Screen views are automatically tracked via `FirebaseAnalyticsObserver` in the navigator.

For manual tracking:

```dart
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('my_screen');
  });
}
```

### Tracking Form Submissions

```dart
void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    
    // Log the event
    await analytics.logSessionCreated(selectedType);
    
    // Save data
    await _saveSession();
  }
}
```

## Custom Events

For events not covered by the service:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

await analytics.logEvent(
  name: 'custom_event_name',
  parameters: {
    'parameter1': 'value1',
    'parameter2': 123,
  },
);
```

## Event Parameters

Most events include relevant parameters:

```dart
// Session created
{
  'session_type': 'training' // or 'competition'
}

// Game created
{
  'score': 150
}

// Statistics viewed
{
  'filter_type': 'all' // or 'training', 'competition'
}

// Chart viewed
{
  'chart_type': 'histogram' // or 'moving_average', 'heatmap'
}
```

## Viewing Analytics Data

### Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Analytics > Events
4. View real-time and historical data

### Key Metrics to Monitor

- **Active Users**: Daily, weekly, monthly active users
- **Session Events**: How often users create/edit/delete sessions
- **Game Events**: Game creation frequency and score distribution
- **Screen Views**: Most visited screens
- **Retention**: User retention over time
- **User Properties**: Distribution of user characteristics

### Custom Dashboards

Create custom dashboards in Firebase Console:
1. Analytics > Custom Dashboards
2. Add relevant metrics and events
3. Filter by user properties or date ranges

## Privacy Considerations

### Data Collection

- Analytics data is anonymous by default
- User IDs are Firebase Auth UIDs (not personal information)
- No personally identifiable information (PII) is logged

### Opt-Out (Future Enhancement)

Consider adding an opt-out option:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
```

### GDPR Compliance

- Inform users about analytics in privacy policy
- Provide option to disable analytics
- Don't log sensitive user data

## Testing Analytics

### Debug Mode

Enable analytics debug mode to see events in real-time:

#### Android
```bash
adb shell setprop debug.firebase.analytics.app com.example.bolometro
```

#### iOS
In Xcode, add `-FIRDebugEnabled` to Arguments Passed On Launch

### DebugView

1. Enable debug mode
2. Go to Firebase Console > Analytics > DebugView
3. See events in real-time as you use the app

### Verifying Events

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

// In development, print events
if (kDebugMode) {
  print('Analytics Event: session_created');
}

await analytics.logSessionCreated('training');
```

## Best Practices

1. **Event Naming**: Use snake_case for event names
2. **Parameter Consistency**: Use same parameter names across similar events
3. **Don't Overdo It**: Track meaningful events, not every tap
4. **Async Operations**: Analytics calls are async but non-blocking
5. **Error Handling**: Analytics failures shouldn't crash the app
6. **Test Thoroughly**: Use DebugView during development

## Common Events Reference

| Event Name | When to Log | Parameters |
|------------|-------------|------------|
| `screen_view` | User navigates to screen | `screen_name`, `screen_class` |
| `session_created` | New session created | `session_type` |
| `game_created` | New game created | `score` |
| `login` | User authenticates | `method` |
| `statistics_viewed` | Statistics page opened | `filter_type` |
| `theme_changed` | Theme preference changed | `theme` |
| `language_changed` | Language preference changed | `language` |
| `share` | User shares content | `content_type` |

## Troubleshooting

### Events Not Appearing

- Check Firebase configuration files are present
- Verify app is connected to Firebase in Console
- Enable debug mode to see real-time events
- Wait up to 24 hours for production events to appear

### Invalid Event Names

- Must be 40 characters or less
- Must start with letter
- Can only contain letters, numbers, underscores
- Case-sensitive

### Too Many Parameters

- Maximum 25 unique parameters per event
- Parameter names must be 40 characters or less
- Parameter values must be 100 characters or less

## Resources

- [Firebase Analytics Documentation](https://firebase.google.com/docs/analytics)
- [Flutter Firebase Analytics Package](https://pub.dev/packages/firebase_analytics)
- [Analytics Best Practices](https://firebase.google.com/docs/analytics/best-practices)
