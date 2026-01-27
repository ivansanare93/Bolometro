# Internationalization (i18n) Guide

Bolometro supports multiple languages using Flutter's built-in internationalization system.

## Supported Languages

- 🇪🇸 Spanish (es) - Default
- 🇬🇧 English (en)

## Configuration

### l10n.yaml
The l10n configuration file defines where localization files are located:

```yaml
arb-dir: lib/l10n
template-arb-file: app_es.arb
output-localization-file: app_localizations.dart
```

### ARB Files
Application Resource Bundle (ARB) files contain all translatable strings:

- `lib/l10n/app_es.arb` - Spanish translations (template)
- `lib/l10n/app_en.arb` - English translations

## Using Localized Strings

### In Dart Code

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In a widget
Text(AppLocalizations.of(context)!.appTitle)

// Common strings
AppLocalizations.of(context)!.save
AppLocalizations.of(context)!.cancel
AppLocalizations.of(context)!.loading
```

### Available Translations

All available translations can be found in the ARB files. Key categories include:

#### Navigation
- `home`, `sessions`, `statistics`, `profile`, `settings`

#### Actions
- `save`, `cancel`, `delete`, `edit`, `confirm`
- `share`, `export`, `import`, `sync`

#### Bowling Terms
- `score`, `average`, `bestGame`, `totalGames`
- `strikes`, `spares`, `frames`
- `training`, `competition`

#### Messages
- `loading`, `noData`, `error`
- `saveSuccess`, `deleteSuccess`, `syncSuccess`
- `saveError`, `deleteError`, `syncError`

#### Settings
- `darkMode`, `lightMode`, `systemMode`
- `language`, `spanish`, `english`

## Adding New Translations

### 1. Add to Spanish ARB (Template)

Edit `lib/l10n/app_es.arb`:

```json
{
  "myNewString": "Mi Nueva Cadena",
  "@myNewString": {
    "description": "Description of what this string is used for"
  }
}
```

### 2. Add to English ARB

Edit `lib/l10n/app_en.arb`:

```json
{
  "myNewString": "My New String",
  "@myNewString": {
    "description": "Description of what this string is used for"
  }
}
```

### 3. Generate Dart Files

```bash
flutter gen-l10n
```

Or simply run:
```bash
flutter pub get
```

The localization files will be auto-generated in `.dart_tool/flutter_gen/gen_l10n/`.

### 4. Use in Code

```dart
Text(AppLocalizations.of(context)!.myNewString)
```

## Strings with Parameters

For strings that need dynamic values:

### ARB File
```json
{
  "welcomeUser": "Bienvenido, {userName}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "userName": {
        "type": "String"
      }
    }
  }
}
```

### Usage
```dart
Text(AppLocalizations.of(context)!.welcomeUser('Juan'))
```

## Plural Strings

For strings that change based on quantity:

### ARB File
```json
{
  "gamesCount": "{count, plural, =0{No hay partidas} =1{1 partida} other{{count} partidas}}",
  "@gamesCount": {
    "description": "Number of games",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

### Usage
```dart
Text(AppLocalizations.of(context)!.gamesCount(5))
```

## Date and Number Formatting

Use the `intl` package for locale-aware formatting:

```dart
import 'package:intl/intl.dart';

// Dates
final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
final formattedDate = dateFormat.format(DateTime.now());

// Numbers
final numberFormat = NumberFormat.decimalPattern(Localizations.localeOf(context).languageCode);
final formattedNumber = numberFormat.format(12345.67);
```

## Changing Language at Runtime

The app uses `LanguageProvider` to manage the current locale:

```dart
final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

// Change to English
languageProvider.setLocale(const Locale('en'));

// Change to Spanish
languageProvider.setLocale(const Locale('es'));
```

## Adding a New Language

### 1. Create ARB File
Create `lib/l10n/app_[locale].arb` (e.g., `app_fr.arb` for French)

### 2. Translate All Strings
Copy all entries from `app_es.arb` and translate them

### 3. Update main.dart
Add the new locale to `supportedLocales`:

```dart
supportedLocales: const [
  Locale('es'),
  Locale('en'),
  Locale('fr'), // Add new locale
],
```

### 4. Update Language Selector UI
Add the new language option in the settings screen

## Best Practices

1. **Always use keys in English** - Makes code more readable
2. **Add descriptions** - Helps translators understand context
3. **Keep strings short** - UI constraints may vary by language
4. **Test all languages** - Ensure UI doesn't break with longer/shorter text
5. **Use gender-neutral language** - When possible
6. **Avoid concatenation** - Use placeholders instead
7. **Never hardcode strings** - Always use localization

## Common Mistakes to Avoid

❌ **Don't**:
```dart
Text('Guardar') // Hardcoded string
```

✅ **Do**:
```dart
Text(AppLocalizations.of(context)!.save)
```

❌ **Don't**:
```dart
Text('Tiene ' + count.toString() + ' partidas') // Concatenation
```

✅ **Do**:
```dart
Text(AppLocalizations.of(context)!.gamesCount(count))
```

## Resources

- [Flutter Internationalization Guide](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB Format Specification](https://github.com/google/app-resource-bundle)
- [Intl Package Documentation](https://pub.dev/packages/intl)
