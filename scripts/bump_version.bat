@echo off
setlocal enabledelayedexpansion

REM Script para incrementar la versión de la app Bolómetro
REM Uso: bump_version.bat [patch|minor|major] ["descripción del cambio"]

if "%~1"=="" (
    echo ❌ Error: Debes especificar el tipo de version [patch^|minor^|major]
    echo.
    echo Uso: bump_version.bat [patch^|minor^|major] ["descripcion del cambio"]
    echo.
    echo Ejemplos:
    echo   bump_version.bat patch "Corregir error en calculo de puntuacion"
    echo   bump_version.bat minor "Agregar graficos de progreso"
    echo   bump_version.bat major "Rediseño completo de UI"
    exit /b 1
)

set "TYPE=%~1"
set "DESCRIPTION=%~2"
set "PUBSPEC=pubspec.yaml"
set "CHANGELOG=CHANGELOG.md"

REM Validar tipo de versión
if not "%TYPE%"=="patch" if not "%TYPE%"=="minor" if not "%TYPE%"=="major" (
    echo ❌ Error: Tipo de version invalido. Usa: patch, minor o major
    exit /b 1
)

REM Leer versión actual del pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" %PUBSPEC%') do set CURRENT_VERSION=%%a

REM Separar version y build number
for /f "tokens=1 delims=+" %%a in ("%CURRENT_VERSION%") do set VERSION=%%a
for /f "tokens=2 delims=+" %%a in ("%CURRENT_VERSION%") do set BUILD=%%a

REM Separar major, minor, patch
for /f "tokens=1 delims=." %%a in ("%VERSION%") do set MAJOR=%%a
for /f "tokens=2 delims=." %%a in ("%VERSION%") do set MINOR=%%a
for /f "tokens=3 delims=." %%a in ("%VERSION%") do set PATCH=%%a

REM Incrementar build number
set /a NEW_BUILD=%BUILD%+1

REM Incrementar versión según tipo
if "%TYPE%"=="major" (
    set /a NEW_MAJOR=%MAJOR%+1
    set NEW_MINOR=0
    set NEW_PATCH=0
    set "CHANGELOG_SECTION=### Cambios Mayores"
)
if "%TYPE%"=="minor" (
    set NEW_MAJOR=%MAJOR%
    set /a NEW_MINOR=%MINOR%+1
    set NEW_PATCH=0
    set "CHANGELOG_SECTION=### Agregado"
)
if "%TYPE%"=="patch" (
    set NEW_MAJOR=%MAJOR%
    set NEW_MINOR=%MINOR%
    set /a NEW_PATCH=%PATCH%+1
    set "CHANGELOG_SECTION=### Corregido"
)

set "NEW_VERSION=!NEW_MAJOR!.!NEW_MINOR!.!NEW_PATCH!"
set "NEW_FULL_VERSION=!NEW_VERSION!+!NEW_BUILD!"

echo.
echo 📦 Bolómetro - Actualización de Versión
echo ========================================
echo 📌 Versión actual:  %CURRENT_VERSION%
echo 🎯 Nueva versión:   !NEW_FULL_VERSION!
echo 📝 Tipo de cambio:  %TYPE%
echo.

REM Confirmar con el usuario
set /p CONFIRM="¿Continuar con la actualización? (S/N): "
if /i not "%CONFIRM%"=="S" (
    echo ❌ Actualización cancelada.
    exit /b 0
)

REM Actualizar pubspec.yaml
powershell -Command "(Get-Content '%PUBSPEC%') -replace '^version:.*', 'version: !NEW_FULL_VERSION!' | Set-Content '%PUBSPEC%'"

echo ✅ pubspec.yaml actualizado

REM Actualizar CHANGELOG.md si existe una descripción
if not "%DESCRIPTION%"=="" (
echo.
echo 📝 Actualizando CHANGELOG.md...
    
    REM Crear entrada temporal para CHANGELOG
    set "DATE_NOW=%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%"
    
    REM Crear archivo temporal con la nueva entrada
    echo ## [!NEW_VERSION!] - !DATE_NOW! > changelog_temp.txt
    echo. >> changelog_temp.txt
    echo !CHANGELOG_SECTION! >> changelog_temp.txt
    echo - %DESCRIPTION% >> changelog_temp.txt
    echo. >> changelog_temp.txt
    
    REM Insertar después de la línea 8 (después de "## [No Publicado]")
    powershell -Command "$content = Get-Content '%CHANGELOG%'; $newEntry = Get-Content 'changelog_temp.txt'; $content[0..7] + $newEntry + $content[8..($content.Length-1)] | Set-Content '%CHANGELOG%'"
    
    del changelog_temp.txt
    echo ✅ CHANGELOG.md actualizado
)

REM Crear commit de Git si el repo está inicializado
git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo 🔧 Git detectado. ¿Crear commit y tag?
    set /p GIT_COMMIT="(S/N): "
    
    if /i "!GIT_COMMIT!"=="S" (
        git add %PUBSPEC% %CHANGELOG%
        git commit -m "chore: bump version to !NEW_FULL_VERSION!"
        git tag -a "v!NEW_VERSION!" -m "Release version !NEW_VERSION!"
        
        echo ✅ Commit y tag creados
        echo.
        echo 💡 Para publicar los cambios ejecuta:
        echo    git push origin main
        echo    git push origin v!NEW_VERSION!
    )
)
echo.
echo ========================================
echo ✅ Versión actualizada exitosamente
echo 🎯 Nueva versión: !NEW_FULL_VERSION!
echo ========================================
echo.
endlocal