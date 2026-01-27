# Correcciones Implementadas

## Fecha: 27 de Enero de 2026

Este documento describe las correcciones implementadas para resolver los problemas reportados en el sistema de autenticación de Bolómetro.

## Problemas Resueltos

### 1. ✅ Permitir continuar sin iniciar sesión

**Problema Original:**
Al hacer clic en "Continuar sin iniciar sesión", la aplicación no navegaba a la pantalla principal y permanecía en la pantalla de login.

**Causa:**
El `AuthWrapper` en `main.dart` no tenía un mecanismo para detectar cuando el usuario elegía continuar sin autenticarse. La condición para mostrar la pantalla de login se cumplía continuamente porque tanto `_hasShownLoginScreen` como `authService.isAuthenticated` permanecían en `false`.

**Solución Implementada:**

1. **Modificaciones en `lib/main.dart`:**
   - Agregado nuevo estado `_skipLogin` para rastrear cuando el usuario elige modo offline
   - Agregado método `_onContinueWithoutLogin()` que actualiza el estado
   - Modificada la condición de renderizado para incluir `!_skipLogin`
   - El `LoginScreen` ahora recibe un callback `onContinueWithoutLogin`

2. **Modificaciones en `lib/screens/login_screen.dart`:**
   - Agregado parámetro opcional `onContinueWithoutLogin` al constructor
   - Actualizado método `_continueOffline()` para invocar el callback
   - El callback notifica al `AuthWrapper` que el usuario ha elegido continuar sin login

**Resultado:**
Ahora cuando el usuario hace clic en "Continuar sin iniciar sesión", la aplicación:
1. Configura el `DataRepository` en modo offline (sin usuario)
2. Notifica al `AuthWrapper` mediante el callback
3. El `AuthWrapper` actualiza su estado (`_skipLogin = true`)
4. La aplicación renderiza la pantalla `HomeScreen`
5. El usuario puede usar todas las funcionalidades de la app en modo local

---

### 2. ✅ Mejorar mensajes de error para Google Sign-In

**Problema Original:**
Al intentar iniciar sesión con Google, se recibía el error:
```
W/HWUI    ( 5010): Failed to choose config with EGL_SWAP_BEHAVIOR_PRESERVED, retrying without...
W/HWUI    ( 5010): Failed to initialize 101010-2 format, error = EGL_SUCCESS
I/flutter ( 5010): Error en signInWithGoogle: PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

**Causa:**
El error `ApiException: 10` indica que la aplicación no está correctamente configurada en Google Cloud Console. Específicamente:
- Falta registrar el SHA-1 fingerprint de la app en Firebase Console
- El archivo `google-services.json` puede estar desactualizado
- El `applicationId` puede no coincidir con el configurado en Firebase

**Solución Implementada:**

1. **Modificaciones en `lib/services/auth_service.dart`:**
   - Mejorada la captura y clasificación de errores en `signInWithGoogle()`
   - Agregada detección específica para `ApiException: 10`
   - Mensajes de error más descriptivos con pasos de solución
   - Referencias a la documentación actualizada

2. **Modificaciones en `AUTENTICACION.md`:**
   - Agregada sección extensa "Error ApiException: 10"
   - Instrucciones paso a paso para obtener el SHA-1:
     - Usando `gradlew signingReport`
     - Usando `keytool` (Windows, macOS, Linux)
     - Para debug y release builds
   - Guía completa para configurar SHA-1 en Firebase Console
   - Pasos para actualizar `google-services.json`
   - Comandos de limpieza y reconstrucción
   - Checklist de verificación de configuración
   - Troubleshooting adicional para otros errores comunes

**Resultado:**
Los usuarios ahora reciben:
1. **Mensajes de error claros y accionables** en la interfaz de la app
2. **Guía paso a paso** en la documentación para resolver el problema
3. **Instrucciones específicas** para cada sistema operativo
4. **Comandos exactos** para copiar y pegar

Ejemplo del mensaje mejorado:
```
Error de configuración de Google Sign-In.

Por favor, verifica:
1. El SHA-1 está registrado en Firebase Console
2. El archivo google-services.json está actualizado
3. El applicationId coincide con el de Firebase

Consulta AUTENTICACION.md para más detalles.
```

---

## Archivos Modificados

1. **`lib/main.dart`**
   - Agregado estado `_skipLogin` en `_AuthWrapperState`
   - Agregado método `_onContinueWithoutLogin()`
   - Modificada lógica de renderizado del `LoginScreen`

2. **`lib/screens/login_screen.dart`**
   - Agregado parámetro `onContinueWithoutLogin` al constructor
   - Modificado método `_continueOffline()` para invocar callback

3. **`lib/services/auth_service.dart`**
   - Mejorado manejo de errores en `signInWithGoogle()`
   - Agregada detección específica de errores comunes
   - Mensajes de error más descriptivos y útiles

4. **`AUTENTICACION.md`**
   - Expandida sección "Solución de Problemas"
   - Agregada guía detallada para ApiException: 10
   - Instrucciones específicas por plataforma
   - Troubleshooting adicional

---

## Flujo de Usuario Actualizado

### Escenario 1: Usuario continúa sin login

```
1. App inicia
2. Se muestra LoginScreen
3. Usuario hace clic en "Continuar sin iniciar sesión"
4. _continueOffline() se ejecuta
5. DataRepository se configura en modo offline (user = null)
6. Se invoca callback onContinueWithoutLogin
7. AuthWrapper actualiza estado (_skipLogin = true)
8. Se renderiza HomeScreen
9. Usuario puede usar la app en modo local
```

### Escenario 2: Usuario intenta login con Google (error de configuración)

```
1. App inicia
2. Se muestra LoginScreen
3. Usuario hace clic en "Continuar con Google"
4. Google Sign-In intenta autenticar
5. Firebase detecta ApiException: 10
6. AuthService captura el error específico
7. Se muestra SnackBar con mensaje descriptivo
8. Usuario consulta AUTENTICACION.md
9. Usuario sigue los pasos para configurar SHA-1
10. Usuario descarga google-services.json actualizado
11. Usuario reconstruye la app
12. Login funciona correctamente
```

### Escenario 3: Usuario inicia sesión exitosamente

```
1. App inicia
2. Se muestra LoginScreen
3. Usuario hace clic en "Continuar con Google"
4. Google Sign-In autentica correctamente
5. Firebase verifica credenciales
6. AuthService actualiza estado (user != null)
7. DataRepository se configura en modo online
8. Se sincronizan datos locales a la nube
9. AuthWrapper detecta autenticación
10. Se renderiza HomeScreen con datos sincronizados
```

---

## Pruebas Recomendadas

Para verificar que las correcciones funcionan correctamente:

### Test 1: Modo Offline
1. Instalar la app en un dispositivo limpio
2. Abrir la app
3. Hacer clic en "Continuar sin iniciar sesión"
4. **Verificar:** La app navega a HomeScreen
5. **Verificar:** Se pueden crear sesiones y partidas
6. **Verificar:** Los datos se guardan localmente en Hive

### Test 2: Google Sign-In (sin configuración)
1. No configurar SHA-1 en Firebase Console
2. Instalar la app
3. Intentar "Continuar con Google"
4. **Verificar:** Se muestra SnackBar con mensaje descriptivo
5. **Verificar:** El mensaje incluye pasos de solución
6. **Verificar:** Se menciona AUTENTICACION.md

### Test 3: Google Sign-In (con configuración correcta)
1. Seguir pasos en AUTENTICACION.md para configurar SHA-1
2. Descargar google-services.json actualizado
3. Reconstruir la app (`flutter clean && flutter run`)
4. Intentar "Continuar con Google"
5. **Verificar:** El login funciona correctamente
6. **Verificar:** Se sincronizan datos a Firestore
7. **Verificar:** Los datos persisten al cerrar/abrir app

### Test 4: Transición Offline -> Online
1. Usar la app en modo offline (crear algunas sesiones)
2. Cerrar la app
3. Reabrir y hacer login con Google
4. **Verificar:** Los datos locales se sincronizan a la nube
5. **Verificar:** No se pierden datos creados offline

---

## Compatibilidad

- **Flutter SDK:** ^3.8.1
- **Dart SDK:** Compatible con la versión de Flutter
- **Android:** minSdk 23 (Android 6.0+)
- **iOS:** Pendiente de configuración
- **Firebase:**
  - Firebase Core: ^2.31.0
  - Firebase Auth: ^4.19.3
  - Google Sign In: ^6.2.1
  - Cloud Firestore: ^4.16.1

---

## Notas Adicionales

### Seguridad
- Las credenciales nunca se almacenan localmente
- Firebase Authentication maneja toda la seguridad
- Los tokens se renuevan automáticamente
- Modo offline usa solo almacenamiento local (Hive)

### Experiencia de Usuario
- El usuario puede cambiar entre modos en cualquier momento
- Los datos locales nunca se pierden
- La sincronización es transparente y automática
- Los errores se comunican de forma clara y accionable

### Próximos Pasos Sugeridos
1. Crear tests automatizados para ambos flujos
2. Agregar telemetría para rastrear tasa de error en login
3. Considerar agregar más proveedores de autenticación (Apple, Email)
4. Implementar sincronización incremental (solo deltas)
5. Agregar modo sin conexión "rico" con cache inteligente

---

**Autor:** GitHub Copilot
**Fecha de Implementación:** 27 de Enero de 2026
**Versión:** 1.0.0
