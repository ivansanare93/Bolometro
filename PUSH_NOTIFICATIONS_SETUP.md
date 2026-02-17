# Notificaciones Push - Guía de Configuración

## Problema Identificado

Las notificaciones push para solicitudes de amistad no funcionaban porque aunque la aplicación Flutter guardaba los tokens FCM y creaba documentos de notificación en Firestore, **no había Cloud Functions configuradas** para enviar las notificaciones push reales a los dispositivos.

## Solución Implementada

Se han creado Cloud Functions de Firebase que automáticamente envían notificaciones push cuando:

1. **Se recibe una solicitud de amistad** - El usuario receptor recibe una notificación push
2. **Se acepta una solicitud de amistad** - El usuario que envió la solicitud recibe una notificación push

## Estructura de Archivos Creados

```
Bolometro/
├── functions/
│   ├── .gitignore
│   ├── .eslintrc.js
│   ├── package.json
│   └── index.js (Cloud Functions)
├── firebase.json
└── firestore.indexes.json
```

## Cómo Funciona

### Flujo de Notificaciones

1. **Usuario envía solicitud de amistad**:
   - `FriendsService.enviarSolicitudAmistad()` crea un documento en Firestore
   - `NotificationService.sendFriendRequestNotification()` crea una notificación en `users/{toUserId}/notifications/`
   - **Cloud Function** se activa automáticamente al detectar la nueva notificación
   - La función obtiene el token FCM del usuario destinatario
   - Envía la notificación push usando Firebase Cloud Messaging

2. **Usuario acepta solicitud**:
   - Similar al proceso anterior pero con `sendFriendRequestAcceptedNotification`

### Componentes Clave

#### Cloud Functions (`functions/index.js`)

Dos funciones principales:

1. `sendFriendRequestNotification`: Activa cuando se crea una notificación de tipo `friend_request`
2. `sendFriendRequestAcceptedNotification`: Activa cuando se crea una notificación de tipo `friend_request_accepted`

Cada función:
- Lee el token FCM del usuario destinatario desde Firestore
- Construye el mensaje de notificación con título, cuerpo y datos personalizados
- Envía la notificación usando Firebase Admin SDK
- Incluye configuración específica para Android (canal de notificación) e iOS (sonido y badge)

## Despliegue de Cloud Functions

### Requisitos Previos

1. **Firebase CLI instalado**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Autenticación con Firebase**:
   ```bash
   firebase login
   ```

3. **Proyecto de Firebase configurado**:
   Asegúrate de que el proyecto actual esté vinculado al proyecto de Firebase correcto.

### Pasos de Despliegue

1. **Navegar al directorio de funciones**:
   ```bash
   cd functions
   ```

2. **Instalar dependencias**:
   ```bash
   npm install
   ```

3. **Verificar que no hay errores de sintaxis** (opcional):
   ```bash
   npm run lint
   ```

4. **Desplegar las funciones**:
   ```bash
   cd ..
   firebase deploy --only functions
   ```

   O desde la raíz del proyecto:
   ```bash
   firebase deploy --only functions
   ```

### Verificación del Despliegue

Después del despliegue, deberías ver en la consola:

```
✔  functions: Finished running predeploy script.
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
...
✔  Deploy complete!
```

Puedes verificar las funciones en la [Consola de Firebase](https://console.firebase.google.com/):
1. Ve a tu proyecto
2. Navega a "Functions" en el menú lateral
3. Deberías ver las dos funciones listadas:
   - `sendFriendRequestNotification`
   - `sendFriendRequestAcceptedNotification`

### Ver Logs de las Funciones

Para ver los logs en tiempo real:

```bash
firebase functions:log
```

O en la Consola de Firebase > Functions > Logs

## Configuración Adicional en Android

El `AndroidManifest.xml` ya incluye los permisos necesarios:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## Pruebas

### Cómo Probar las Notificaciones

1. **Asegúrate de que las Cloud Functions estén desplegadas**

2. **En un dispositivo/emulador A**:
   - Inicia sesión con un usuario
   - Asegúrate de que los permisos de notificación estén habilitados

3. **En un dispositivo/emulador B**:
   - Inicia sesión con otro usuario
   - Busca al usuario A por email o código de amigo
   - Envía una solicitud de amistad

4. **Verifica**:
   - El dispositivo A debería recibir una notificación push
   - Si acepta la solicitud, el dispositivo B debería recibir una notificación

### Solución de Problemas

Si las notificaciones no llegan:

1. **Verifica los logs de Cloud Functions**:
   ```bash
   firebase functions:log
   ```

2. **Verifica que el token FCM se esté guardando**:
   - En la consola de Firebase > Firestore
   - Busca el documento del usuario
   - Verifica que tenga el campo `fcmToken`

3. **Verifica los permisos de notificación en el dispositivo**:
   - Android: Configuración > Aplicaciones > Bolómetro > Notificaciones
   - Los permisos deben estar habilitados

4. **Verifica que las notificaciones se estén creando en Firestore**:
   - Firebase Console > Firestore
   - Navega a `users/{userId}/notifications`
   - Deberías ver los documentos de notificación

5. **Verifica la configuración de Firebase**:
   - El archivo `google-services.json` debe estar actualizado
   - El proyecto debe tener Firebase Cloud Messaging habilitado

## Costos

Las Cloud Functions de Firebase tienen un nivel gratuito generoso:
- **2 millones de invocaciones/mes gratis**
- Para una app de bolos con solicitudes de amistad ocasionales, probablemente permanecerá en el nivel gratuito

## Seguridad

Las funciones solo se activan cuando:
1. Se crea un documento en la colección `notifications`
2. Las reglas de Firestore ya controlan quién puede crear notificaciones
3. Solo usuarios autenticados pueden crear notificaciones de tipo `friend_request` y `friend_request_accepted`

## Mantenimiento

### Actualizar las Funciones

Si necesitas modificar las funciones:

1. Edita `functions/index.js`
2. Despliega los cambios:
   ```bash
   firebase deploy --only functions
   ```

### Monitoreo

Monitorea el uso y rendimiento en:
- Firebase Console > Functions > Dashboard
- Aquí puedes ver invocaciones, errores, tiempo de ejecución, etc.

## Notas Adicionales

- Las notificaciones incluyen datos personalizados (`type`, `requestId`, etc.) que la app puede usar para navegación
- El canal de notificación de Android se llama `friend_requests` - asegúrate de que esté configurado en la app si quieres personalizar el comportamiento
- Las notificaciones iOS incluyen badge y sonido por defecto
