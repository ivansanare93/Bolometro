# Integración de Google Play Integrity API

## Resumen

Bolómetro utiliza **Firebase App Check** con **Google Play Integrity** para verificar que las solicitudes a Firebase (Firestore, Auth, Cloud Messaging, etc.) provienen de una instancia auténtica y no modificada de la aplicación.

Esto protege el inicio de sesión con Google y todos los servicios de Firebase frente a:
- Clientes falsos o scripts automatizados.
- Versiones modificadas (re-empaquetadas) de la app.
- Dispositivos que no superan las comprobaciones de seguridad de Android.

---

## Cómo funciona

```
Dispositivo Android
       │
       ▼
Google Play Integrity API  ──→  genera token firmado
       │
       ▼
Firebase App Check SDK  ──→  adjunta el token a cada solicitud Firebase
       │
       ▼
Servicios Firebase (Auth / Firestore / Messaging)
       │
       ▼
Firebase App Check  ──→  valida el token antes de procesar la solicitud
```

1. Al iniciar la app, `IntegrityService.activate()` registra el proveedor Play Integrity con Firebase App Check.
2. Antes de cada inicio de sesión con Google, `AuthService.signInWithGoogle()` solicita un token de App Check actualizado.
3. Firebase SDK añade automáticamente el token a todas las solicitudes a servicios de Firebase.
4. Firebase rechaza las solicitudes que no lleven un token válido (cuando la regla de cumplimiento está activa).

---

## Configuración en Firebase Console

### 1. Activar App Check para el proyecto

1. Abre [Firebase Console](https://console.firebase.google.com/) → tu proyecto Bolómetro.
2. Ve a **App Check** (menú lateral).
3. Selecciona la app Android **com.bolometro**.
4. Elige **Play Integrity** como proveedor de atestación.
5. Haz clic en **Guardar**.

### 2. Registrar la huella digital SHA-256 (necesaria para Play Integrity)

Play Integrity valida que el APK/AAB esté firmado con la clave correcta.

#### Obtener la huella SHA-256 de la clave de lanzamiento

```bash
keytool -list -v -keystore <ruta/a/tu/keystore.jks> \
  -alias <nombre_del_alias> -storepass <contraseña>
```

También puedes obtenerla de Google Play Console:
> Play Console → Tu app → Configuración → Integridad de la app → Certificado de firma de la app → **SHA-256**

#### Agregar la huella en Firebase Console

1. Firebase Console → Configuración del proyecto → Tu app Android.
2. En **Huellas digitales de certificados SHA**, haz clic en **Agregar huella digital**.
3. Pega el SHA-256.
4. Descarga el `google-services.json` actualizado y reemplaza `android/app/google-services.json`.

---

## Modo depuración (desarrollo)

En compilaciones `kDebugMode` la app usa el **proveedor de depuración** de App Check, que no requiere Google Play ni firmar el APK.

### Obtener el token de depuración

1. Ejecuta la app en modo debug y busca en los logs:
   ```
   Firebase App Check debug token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
2. En Firebase Console → App Check → **Administrar tokens de depuración** → añade el token.

> **Nota:** Nunca compartas ni subas este token al repositorio.

---

## Cumplimiento (enforcement)

Una vez probado en producción, puedes activar el cumplimiento estricto para que Firebase rechace solicitudes sin token válido:

1. Firebase Console → App Check → Tu app → **Aplicar**.
2. Activa el cumplimiento para **Firestore**, **Authentication**, y **Cloud Messaging**.

> ⚠️ Activa el cumplimiento solo cuando hayas confirmado que el token de App Check llega correctamente desde la app distribuida en Play Store.

---

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | Agregada dependencia `firebase_app_check: ^0.3.1+6` |
| `lib/main.dart` | Llamada a `IntegrityService().activate()` tras `Firebase.initializeApp()` |
| `lib/services/integrity_service.dart` | Nuevo servicio que encapsula la activación de App Check |
| `lib/services/auth_service.dart` | Refresh del token App Check antes del login con Google; nuevo caso de error |
| `functions/index.js` | Helper `verifyAppCheck()` para validación en Cloud Functions |

---

## Solución de problemas

### "App Check token no disponible"
- Asegúrate de que Google Play Services esté actualizado.
- Verifica que la app esté instalada desde Google Play (en producción).
- En desarrollo, confirma que el token de depuración esté añadido en Firebase Console.

### Error en modo release: "Integrity API error"
- Verifica que el SHA-256 de tu keystore coincide con el registrado en Firebase Console y Play Console.
- Asegúrate de que la app se haya descargado de Google Play (no instalada lateralmente como APK).

### Play Integrity no disponible en el dispositivo
- El servicio requiere Android 5.0+ con Google Play Services instalado.
- En dispositivos sin Google Play (p.ej. algunos emuladores o tablets de China), App Check se desactivará automáticamente sin bloquear la app.
