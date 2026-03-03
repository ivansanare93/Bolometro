# Guía de Internacionalización (i18n)

Bolometro soporta múltiples idiomas usando el sistema de internacionalización integrado de Flutter.

## Idiomas Soportados

- 🇪🇸 Español (es) - Por defecto
- 🇬🇧 Inglés (en)

## Configuración

### l10n.yaml
El archivo de configuración l10n define dónde se encuentran los archivos de localización:

```yaml
arb-dir: lib/l10n
template-arb-file: app_es.arb
output-localization-file: app_localizations.dart
```

### Archivos ARB
Los archivos Application Resource Bundle (ARB) contienen todas las cadenas traducibles:

- `lib/l10n/app_es.arb` - Traducciones en español (plantilla)
- `lib/l10n/app_en.arb` - Traducciones en inglés

## Usar Cadenas Localizadas

### En Código Dart

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// En un widget
Text(AppLocalizations.of(context)!.appTitle)

// Cadenas comunes
AppLocalizations.of(context)!.save
AppLocalizations.of(context)!.cancel
AppLocalizations.of(context)!.loading
```

### Traducciones Disponibles

Todas las traducciones disponibles se pueden encontrar en los archivos ARB. Las categorías clave incluyen:

#### Navegación
- `home`, `sessions`, `statistics`, `profile`, `settings`

#### Acciones
- `save`, `cancel`, `delete`, `edit`, `confirm`
- `share`, `export`, `import`, `sync`

#### Términos de Boliche
- `score`, `average`, `bestGame`, `totalGames`
- `strikes`, `spares`, `frames`
- `training`, `competition`

#### Mensajes
- `loading`, `noData`, `error`
- `saveSuccess`, `deleteSuccess`, `syncSuccess`
- `saveError`, `deleteError`, `syncError`

#### Configuración
- `darkMode`, `lightMode`, `systemMode`
- `language`, `spanish`, `english`

## Agregar Nuevas Traducciones

### 1. Agregar al ARB en Español (Plantilla)

Edita `lib/l10n/app_es.arb`:

```json
{
  "myNewString": "Mi Nueva Cadena",
  "@myNewString": {
    "description": "Descripción de para qué se usa esta cadena"
  }
}
```

### 2. Agregar al ARB en Inglés

Edita `lib/l10n/app_en.arb`:

```json
{
  "myNewString": "My New String",
  "@myNewString": {
    "description": "Description of what this string is used for"
  }
}
```

### 3. Generar Archivos Dart

```bash
flutter gen-l10n
```

O simplemente ejecuta:
```bash
flutter pub get
```

Los archivos de localización se generarán automáticamente en `.dart_tool/flutter_gen/gen_l10n/`.

### 4. Usar en Código

```dart
Text(AppLocalizations.of(context)!.myNewString)
```

## Cadenas con Parámetros

Para cadenas que necesitan valores dinámicos:

### Archivo ARB
```json
{
  "welcomeUser": "Bienvenido, {userName}!",
  "@welcomeUser": {
    "description": "Mensaje de bienvenida con nombre de usuario",
    "placeholders": {
      "userName": {
        "type": "String"
      }
    }
  }
}
```

### Uso
```dart
Text(AppLocalizations.of(context)!.welcomeUser('Juan'))
```

## Cadenas Plurales

Para cadenas que cambian según la cantidad:

### Archivo ARB
{% raw %}
```json
{
  "gamesCount": "{count, plural, =0{No hay partidas} =1{1 partida} other{{count} partidas}}",
  "@gamesCount": {
    "description": "Número de partidas",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```
{% endraw %}

### Uso
```dart
Text(AppLocalizations.of(context)!.gamesCount(5))
```

## Formato de Fechas y Números

Usa el paquete `intl` para formato consciente de locale:

```dart
import 'package:intl/intl.dart';

// Fechas
final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
final formattedDate = dateFormat.format(DateTime.now());

// Números
final numberFormat = NumberFormat.decimalPattern(Localizations.localeOf(context).languageCode);
final formattedNumber = numberFormat.format(12345.67);
```

## Cambiar Idioma en Tiempo de Ejecución

La app usa `LanguageProvider` para gestionar el locale actual:

```dart
final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

// Cambiar a inglés
languageProvider.setLocale(const Locale('en'));

// Cambiar a español
languageProvider.setLocale(const Locale('es'));
```

## Agregar un Nuevo Idioma

### 1. Crear Archivo ARB
Crea `lib/l10n/app_[locale].arb` (ej., `app_fr.arb` para francés)

### 2. Traducir Todas las Cadenas
Copia todas las entradas de `app_es.arb` y tradúcelas

### 3. Actualizar main.dart
Agrega el nuevo locale a `supportedLocales`:

```dart
supportedLocales: const [
  Locale('es'),
  Locale('en'),
  Locale('fr'), // Agregar nuevo locale
],
```

### 4. Actualizar UI del Selector de Idioma
Agrega la nueva opción de idioma en la pantalla de configuración

## Mejores Prácticas

1. **Usa siempre claves en inglés** - Hace el código más legible
2. **Agrega descripciones** - Ayuda a los traductores a entender el contexto
3. **Mantén las cadenas cortas** - Las restricciones de UI pueden variar por idioma
4. **Prueba todos los idiomas** - Asegúrate de que la UI no se rompa con texto más largo/corto
5. **Usa lenguaje neutral de género** - Cuando sea posible
6. **Evita concatenación** - Usa marcadores de posición en su lugar
7. **Nunca hardcodees cadenas** - Usa siempre localización

## Errores Comunes a Evitar

❌ **No hacer**:
```dart
Text('Guardar') // Cadena hardcodeada
```

✅ **Hacer**:
```dart
Text(AppLocalizations.of(context)!.save)
```

❌ **No hacer**:
```dart
Text('Tiene ' + count.toString() + ' partidas') // Concatenación
```

✅ **Hacer**:
```dart
Text(AppLocalizations.of(context)!.gamesCount(count))
```

## Recursos

- [Guía de Internacionalización de Flutter](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Especificación del Formato ARB](https://github.com/google/app-resource-bundle)
- [Documentación del Paquete Intl](https://pub.dev/packages/intl)
