# Guía de Testing y Despliegue

## Resumen de Cambios

Se han implementado dos correcciones importantes:

1. ✅ **Modo sin conexión funciona correctamente**: Los usuarios ahora pueden continuar sin iniciar sesión y usar la app completamente.

2. ✅ **Mensajes de error mejorados para Google Sign-In**: Errores específicos con guías de solución, especialmente para el error común ApiException: 10.

## Pasos para Probar los Cambios

### 1. Preparar el Entorno

```bash
# Asegúrate de estar en el branch correcto
git checkout copilot/fix-google-sign-in-error

# Actualiza las dependencias
flutter pub get

# Limpia build anterior
flutter clean
```

### 2. Test 1: Modo Sin Conexión

Este test verifica que el usuario puede usar la app sin iniciar sesión.

```bash
# Compilar y ejecutar en modo debug
flutter run
```

**Pasos de prueba:**
1. La app debe mostrar la pantalla de login al iniciar
2. Hacer clic en "Continuar sin iniciar sesión"
3. ✓ **Verificar**: La app navega automáticamente a la pantalla principal (HomeScreen)
4. ✓ **Verificar**: Puedes crear sesiones y partidas
5. Cerrar y reabrir la app
6. ✓ **Verificar**: La app va directamente a HomeScreen (no muestra login de nuevo)
7. ✓ **Verificar**: Los datos creados se mantienen (guardados en Hive local)

**Resultado esperado:**
- La navegación debe ser instantánea al hacer clic en "Continuar sin iniciar sesión"
- No debe haber errores en la consola
- Los datos deben persistir entre sesiones

---

### 3. Test 2: Error de Configuración de Google Sign-In

Este test verifica que los mensajes de error son claros y útiles.

**Escenario A: Sin configurar SHA-1 (ApiException: 10)**

```bash
# NO configures el SHA-1 todavía
flutter run
```

**Pasos de prueba:**
1. Hacer clic en "Continuar con Google"
2. Seleccionar una cuenta de Google
3. ✓ **Verificar**: Se muestra un SnackBar rojo con mensaje descriptivo
4. ✓ **Verificar**: El mensaje menciona:
   - SHA-1 no configurado
   - google-services.json desactualizado
   - applicationId debe coincidir
   - Referencia a AUTENTICACION.md

**Resultado esperado:**
```
Error de configuración de Google Sign-In.

Por favor, verifica:
1. El SHA-1 está registrado en Firebase Console
2. El archivo google-services.json está actualizado
3. El applicationId coincide con el de Firebase

Consulta AUTENTICACION.md para más detalles.
```

---

### 4. Test 3: Configurar Google Sign-In Correctamente

Ahora vamos a configurar correctamente Google Sign-In.

#### Paso A: Obtener SHA-1

```bash
cd android
./gradlew signingReport
```

Busca en la salida la línea que dice `SHA1:` en la sección `Variant: debug`. Copia ese valor.

**Ejemplo de salida:**
```
Variant: debug
Config: debug
Store: /home/user/.android/debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
SHA-256: ...
```

Copia el valor completo de SHA1 (ej: `AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD`)

#### Paso B: Agregar SHA-1 a Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona el proyecto Bolómetro
3. Haz clic en el ícono de engranaje (⚙️) > "Configuración del proyecto"
4. Desplázate hasta "Tus apps"
5. Selecciona la app Android (com.bolometro)
6. En "Huellas digitales de certificados SHA", haz clic en "Agregar huella digital"
7. Pega el SHA-1 que copiaste
8. Haz clic en "Guardar"

#### Paso C: Descargar google-services.json actualizado

1. Después de agregar el SHA-1, descarga el nuevo `google-services.json`
2. Reemplaza el archivo en `android/app/google-services.json`

#### Paso D: Verificar que Google Sign-In esté habilitado

1. En Firebase Console, ve a "Authentication"
2. Haz clic en la pestaña "Sign-in method"
3. ✓ **Verificar**: "Google" está habilitado
4. Si no está habilitado:
   - Haz clic en "Google"
   - Activa el interruptor "Habilitar"
   - Agrega un correo de soporte del proyecto
   - Haz clic en "Guardar"

#### Paso E: Reconstruir y probar

```bash
cd ..  # Volver a la raíz del proyecto
flutter clean
flutter pub get
flutter run
```

**Pasos de prueba:**
1. Hacer clic en "Continuar con Google"
2. Seleccionar una cuenta de Google
3. ✓ **Verificar**: El login se completa exitosamente (sin errores)
4. ✓ **Verificar**: Se muestra la pantalla principal (HomeScreen)
5. ✓ **Verificar**: Si hay datos locales, se sincronizan automáticamente a Firestore
6. Crear una nueva sesión con partida
7. ✓ **Verificar**: Los datos se guardan tanto localmente como en Firestore
8. Cerrar sesión desde la app (si hay opción en el menú de ajustes)
9. ✓ **Verificar**: Los datos locales se mantienen
10. Iniciar sesión de nuevo
11. ✓ **Verificar**: Los datos se muestran correctamente

**Resultado esperado:**
- El login debe funcionar sin errores
- Los datos deben sincronizarse automáticamente
- No debe haber errores en la consola

---

### 5. Test 4: Cambiar de Modo Offline a Online

Este test verifica la transición entre modos.

```bash
flutter run
```

**Pasos de prueba:**
1. Hacer clic en "Continuar sin iniciar sesión" (modo offline)
2. Crear 2-3 sesiones con partidas
3. ✓ **Verificar**: Los datos se guardan localmente
4. Ir a ajustes/configuración en la app
5. Iniciar sesión con Google
6. ✓ **Verificar**: El login funciona correctamente
7. ✓ **Verificar**: Los datos creados en modo offline se sincronizan automáticamente
8. ✓ **Verificar**: Puedes ver los datos en Firebase Console > Firestore Database

**Resultado esperado:**
- Los datos creados en modo offline deben aparecer en Firestore
- No debe haber pérdida de datos
- La sincronización debe ser transparente para el usuario

---

### 6. Test 5: Múltiples Dispositivos

Este test verifica que la sincronización funciona entre dispositivos.

**Dispositivo 1:**
1. Iniciar sesión con Google
2. Crear sesiones y partidas
3. ✓ **Verificar**: Los datos se guardan en Firestore

**Dispositivo 2:**
1. Instalar la app
2. Iniciar sesión con la misma cuenta de Google
3. ✓ **Verificar**: Los datos del Dispositivo 1 aparecen automáticamente
4. Crear nuevas sesiones
5. ✓ **Verificar**: Los datos se sincronizan

**Dispositivo 1 (de nuevo):**
1. Refrescar la lista de sesiones (pull-to-refresh)
2. ✓ **Verificar**: Los datos creados en Dispositivo 2 aparecen

**Resultado esperado:**
- Los datos deben sincronizarse correctamente entre dispositivos
- No debe haber duplicados
- Los cambios deben ser visibles al refrescar

---

## Verificación de Errores Comunes

### Error de Red (Sin Internet)

**Simular:**
1. Desactivar WiFi y datos móviles
2. Intentar iniciar sesión con Google

**Resultado esperado:**
```
Error de conexión.
Verifica tu conexión a Internet e intenta nuevamente.
```

### Cuenta Deshabilitada

**Simular:**
1. En Firebase Console > Authentication > Users
2. Deshabilitar un usuario
3. Intentar iniciar sesión con esa cuenta

**Resultado esperado:**
```
Esta cuenta ha sido deshabilitada.
Contacta al soporte para más información.
```

---

## Checklist de Aprobación

Antes de fusionar este PR, verifica:

- [ ] Test 1 pasa: Modo offline funciona correctamente
- [ ] Test 2 pasa: Mensajes de error son claros para ApiException: 10
- [ ] Test 3 pasa: Google Sign-In funciona después de configurar SHA-1
- [ ] Test 4 pasa: Transición offline → online funciona
- [ ] Test 5 pasa: Sincronización entre dispositivos funciona
- [ ] No hay errores en la consola durante las pruebas
- [ ] No hay crashes o comportamientos inesperados
- [ ] Los datos persisten correctamente
- [ ] La documentación (AUTENTICACION.md, FIXES_IMPLEMENTADOS.md) es precisa

---

## Logs Útiles para Debugging

Durante las pruebas, observa estos logs:

```bash
# Ver logs en tiempo real
flutter logs

# Buscar errores específicos
flutter logs | grep "Error"
flutter logs | grep "Exception"

# Buscar logs de autenticación
flutter logs | grep "signInWithGoogle"
flutter logs | grep "AuthService"
```

---

## Rollback (Si algo sale mal)

Si encuentras problemas críticos:

```bash
# Volver al branch principal
git checkout main

# O volver al commit anterior
git log  # Busca el commit anterior
git checkout <commit-hash>

# Reconstruir
flutter clean
flutter pub get
flutter run
```

---

## Próximos Pasos Después de Aprobar

1. Fusionar el PR a la rama principal
2. Crear un release tag: `git tag v1.1.0-auth-fixes`
3. Generar APK de producción:
   ```bash
   flutter build apk --release
   ```
4. Probar el APK de release en dispositivos reales
5. Publicar en Play Store (si aplica)
6. Monitorear crashlytics/analytics para detectar problemas

---

## Soporte y Contacto

Si encuentras problemas durante las pruebas:

1. Revisa AUTENTICACION.md para troubleshooting detallado
2. Revisa FIXES_IMPLEMENTADOS.md para entender los cambios
3. Consulta los logs de Flutter para detalles técnicos
4. Verifica que todos los pasos de configuración se siguieron correctamente

---

**Última actualización:** 2026-01-27
**Versión de la App:** 1.0.0+1
**Flutter SDK Requerido:** última versión estable
