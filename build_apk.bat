@echo off
echo Limpiando proyecto...
flutter clean

echo Actualizando dependencias...
flutter pub get

echo Generando APK de producción...
flutter build apk --release

echo --------------------------------------
echo ✅ APK generado exitosamente.
echo 📁 build\app\outputs\flutter-apk\app-release.apk
pause
