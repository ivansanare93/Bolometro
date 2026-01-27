# Guía de CI/CD

Bolometro utiliza GitHub Actions para Integración Continua y Despliegue Continuo.

## Descripción General del Flujo de Trabajo

El pipeline CI/CD está definido en `.github/workflows/flutter-ci.yml` y se ejecuta en:
- Push a las ramas `main` y `develop`
- Pull requests a las ramas `main` y `develop`

## Etapas del Pipeline

### 1. Test and Analyze

**Se ejecuta en**: `ubuntu-latest`

**Pasos**:
1. **Checkout code** - Obtiene el código más reciente del repositorio
2. **Setup Flutter** - Instala la última versión estable de Flutter
3. **Install dependencies** - Ejecuta `flutter pub get`
4. **Verify formatting** - Verifica el formato del código (continúa si hay error)
5. **Analyze code** - Ejecuta `flutter analyze` para verificar problemas
6. **Run tests** - Ejecuta todas las pruebas con cobertura
7. **Upload coverage** - Envía el reporte de cobertura a Codecov

### 2. Build Android

**Se ejecuta en**: `ubuntu-latest`  
**Depende de**: Trabajo Test and Analyze

**Pasos**:
1. **Checkout code**
2. **Setup Flutter**
3. **Install dependencies**
4. **Build APK** - Crea APK de release
5. **Upload artifact** - Almacena APK para descarga

### 3. Build iOS

**Se ejecuta en**: `macos-latest`  
**Depende de**: Trabajo Test and Analyze

**Pasos**:
1. **Checkout code**
2. **Setup Flutter**
3. **Install dependencies**
4. **Build iOS** - Crea compilación iOS sin codesigning

## Configuración

### Versión de Flutter

El proyecto está configurado para usar siempre la última versión estable de Flutter.

Configuración actual:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    channel: 'stable'
```

Si necesitas especificar una versión específica (no recomendado), puedes agregar:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.10.0' # Especifica una versión aquí
    channel: 'stable'
```

### Cobertura de Pruebas

La cobertura se sube automáticamente a Codecov. Para ver:
1. Ve a tu repositorio en GitHub
2. Verifica el badge de Codecov en README
3. Haz clic para ver el reporte de cobertura detallado

### Artefactos

Los artefactos de compilación se retienen por 90 días por defecto y pueden descargarse desde la pestaña Actions.

## Desarrollo Local

### Antes de Hacer Push de Código

Ejecuta estos comandos localmente para detectar problemas temprano:

```bash
# Formatear código
dart format .

# Analizar código
flutter analyze

# Ejecutar pruebas
flutter test

# Ejecutar pruebas con cobertura
flutter test --coverage
```

### Verificaciones Pre-commit

Considera agregar un hook pre-commit:

```bash
# Crear .git/hooks/pre-commit
#!/bin/bash

echo "Ejecutando verificaciones pre-commit..."

# Verificación de formato
if ! dart format --output=none --set-exit-if-changed .; then
    echo "Formateo de código falló. Ejecuta: dart format ."
    exit 1
fi

# Analizar
if ! flutter analyze; then
    echo "Flutter analyze falló."
    exit 1
fi

# Pruebas
if ! flutter test; then
    echo "Las pruebas fallaron."
    exit 1
fi

echo "¡Todas las verificaciones pasaron!"
```

Hacerlo ejecutable:
```bash
chmod +x .git/hooks/pre-commit
```

## Manejo de Fallos de Compilación

### Fallos de Pruebas

1. Verifica los logs de pruebas en GitHub Actions
2. Corrige las pruebas que fallan localmente
3. Ejecuta `flutter test` para verificar
4. Haz push de la corrección

### Fallos de Compilación

#### Problemas de Compilación Android

Causas comunes:
- Incompatibilidad de versión de Gradle
- Desajuste de versión de SDK
- Dependencias faltantes

Solución:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### Problemas de Compilación iOS

Causas comunes:
- Problemas con CocoaPods
- Incompatibilidad de versión de Xcode
- Certificados faltantes (no aplicable para CI)

Solución:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter build ios --no-codesign
```

### Problemas de Análisis

Flutter analyze muestra warnings/errores:

1. Corrige todos los errores antes de hacer commit
2. Aborda los warnings cuando sea posible
3. Usa `// ignore: rule_name` con moderación para excepciones válidas

```dart
// ignore: avoid_print
print('Mensaje de depuración');
```

## Agregar Nuevos Flujos de Trabajo

### Ejemplo de Flujo de Trabajo de Despliegue

Crea `.github/workflows/deploy.yml`:

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
          channel: 'stable'
          
      - name: Build App Bundle
        run: flutter build appbundle --release
        
      - name: Deploy to Play Store
        # Agregar pasos de despliegue aquí
```

### Pruebas Programadas

Ejecutar pruebas nocturnas:

```yaml
name: Nightly Tests

on:
  schedule:
    - cron: '0 2 * * *' # Se ejecuta a las 2 AM UTC diariamente

jobs:
  test:
    # Igual que el trabajo test en flutter-ci.yml
```

## Gestión de Secretos

### Agregar Secretos

1. Ve a Configuración del Repositorio > Secrets and variables > Actions
2. Haz clic en "New repository secret"
3. Agrega nombre y valor del secreto

### Usar Secretos

```yaml
- name: Paso usando secreto
  env:
    SECRET_KEY: ${{ secrets.SECRET_KEY }}
  run: echo "Usando secreto"
```

### Secretos Comunes

Para despliegue, podrías necesitar:
- `ANDROID_KEYSTORE` - Keystore codificado en Base64
- `KEYSTORE_PASSWORD` - Contraseña del keystore
- `KEY_PASSWORD` - Contraseña de la clave
- `APPLE_CERTIFICATE` - Certificado iOS
- `PROVISIONING_PROFILE` - Perfil de provisioning iOS

## Variables de Entorno

### Configurar Variables de Entorno

```yaml
env:
  FLUTTER_CHANNEL: 'stable'
  
jobs:
  test:
    env:
      TEST_ENV: 'ci'
```

### Usar en Scripts

```yaml
- name: Imprimir entorno
  run: |
    echo "Canal de Flutter: $FLUTTER_CHANNEL"
    echo "Entorno de prueba: $TEST_ENV"
```

## Caché

### Cachear Dependencias

Acelera las compilaciones mediante caché:

```yaml
- name: Cache pub dependencies
  uses: actions/cache@v3
  with:
    path: ${{ env.PUB_CACHE }}
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-pub-
```

### Cachear Artefactos de Compilación

```yaml
- name: Cache build artifacts
  uses: actions/cache@v3
  with:
    path: |
      build
      .dart_tool
    key: ${{ runner.os }}-build-${{ hashFiles('**/pubspec.lock') }}
```

## Badges de Estado

Agrega badges de estado al README:

```markdown
![Flutter CI](https://github.com/ivansanare93/Bolometro/workflows/Flutter%20CI/badge.svg)
[![codecov](https://codecov.io/gh/ivansanare93/Bolometro/branch/main/graph/badge.svg)](https://codecov.io/gh/ivansanare93/Bolometro)
```

## Monitoreo

### Dashboard de GitHub Actions

- Ver todas las ejecuciones de flujo de trabajo
- Descargar logs
- Re-ejecutar trabajos fallidos
- Cancelar trabajos en ejecución

### Notificaciones por Email

GitHub envía notificaciones por email en:
- Fallos de flujo de trabajo
- Primer éxito después de un fallo

Configurar en: Settings > Notifications

## Mejores Prácticas

1. **Mantén los flujos de trabajo rápidos** - Usa caché, trabajos paralelos
2. **Falla rápido** - Ejecuta pruebas antes de compilaciones
3. **Usa compilaciones matriciales** - Prueba múltiples versiones de Flutter/plataformas
4. **Mantén los secretos seguros** - Nunca registres secretos en logs
5. **Documenta los flujos de trabajo** - Agrega comentarios explicando pasos complejos
6. **Bloquea versiones** - Fija versiones de actions para reproducibilidad
7. **Prueba localmente primero** - No dependas del CI para detectar errores básicos

## Solución de Problemas

### Flujo de Trabajo No se Dispara

- Verifica nombres de ramas en `on.push.branches`
- Verifica que el archivo de flujo de trabajo esté en `.github/workflows/`
- Asegúrate de que la sintaxis YAML sea válida

### Errores de Permisos

Agrega permisos al flujo de trabajo:

```yaml
permissions:
  contents: read
  packages: write
```

### Problemas de Timeout

Aumenta el timeout:

```yaml
jobs:
  test:
    timeout-minutes: 30 # El valor por defecto es 360
```

## Recursos

- [Documentación de GitHub Actions](https://docs.github.com/en/actions)
- [Guía de CI/CD de Flutter](https://docs.flutter.dev/deployment/cd)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
