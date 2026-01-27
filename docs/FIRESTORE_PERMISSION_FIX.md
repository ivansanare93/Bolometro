# Solución al Error de Permisos de Firestore

## Problema

Si ves el siguiente error en la consola:

```
I/flutter ( 5353): Error al obtener sesiones paginadas desde Firestore: 
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

Esto significa que las reglas de seguridad de Firestore no están configuradas correctamente o no han sido desplegadas.

## Causa

Las estadísticas funcionan porque cargan datos desde el almacenamiento local (Hive), pero cuando la app intenta obtener sesiones desde Firestore en modo online, las reglas de seguridad están bloqueando el acceso.

## Solución

### Paso 1: Verificar las Reglas de Firestore

Este repositorio incluye el archivo `firestore.rules` con las reglas de seguridad correctas. Sin embargo, estas reglas deben ser **desplegadas manualmente a Firebase**.

### Paso 2: Desplegar las Reglas

Tienes dos opciones para desplegar las reglas:

#### Opción A: Firebase Console (Recomendado para usuarios sin Firebase CLI)

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. En el menú lateral, ve a **Firestore Database**
4. Haz clic en la pestaña **Reglas** (Rules)
5. Copia y pega el siguiente contenido (del archivo `firestore.rules`):

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas para la colección de usuarios
    match /users/{userId} {
      // Solo el usuario puede leer y escribir su propio perfil
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Reglas para la subcolección de sesiones
      match /sesiones/{sesionId} {
        // Solo el propietario puede leer, escribir y eliminar sus sesiones
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        // Validaciones adicionales para escritura
        allow create: if request.auth != null 
                      && request.auth.uid == userId
                      && request.resource.data.keys().hasAll(['fecha', 'lugar', 'tipo', 'partidas'])
                      && request.resource.data.tipo in ['Entrenamiento', 'Competición'];
        
        allow update: if request.auth != null 
                      && request.auth.uid == userId
                      && request.resource.data.keys().hasAll(['fecha', 'lugar', 'tipo', 'partidas'])
                      && request.resource.data.tipo in ['Entrenamiento', 'Competición'];
      }
    }
    
    // Denegar acceso a cualquier otra ruta
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

6. Haz clic en **Publicar** (Publish)
7. Espera unos segundos para que se propaguen los cambios

#### Opción B: Firebase CLI

Si tienes Firebase CLI instalado:

1. Instala Firebase CLI (si no lo tienes):
```bash
npm install -g firebase-tools
```

2. Inicia sesión en Firebase:
```bash
firebase login
```

3. Inicializa Firebase en el proyecto (solo la primera vez):
```bash
firebase init firestore
```
   - Selecciona tu proyecto de Firebase
   - Usa `firestore.rules` como archivo de reglas
   - No sobrescribas el archivo existente

4. Despliega las reglas:
```bash
firebase deploy --only firestore:rules
```

### Paso 3: Verificar el Despliegue

1. En Firebase Console, ve a **Firestore Database > Reglas**
2. Verifica que las reglas desplegadas coincidan con el archivo `firestore.rules`
3. Verifica la fecha/hora de la última modificación

### Paso 4: Probar la App

1. Cierra completamente la app
2. Vuelve a abrirla
3. Inicia sesión con tu cuenta de Google
4. Intenta navegar a la lista de sesiones
5. El error de permisos debería haber desaparecido

## Explicación Técnica

### ¿Por qué funcionan las estadísticas pero no las sesiones?

- **Estadísticas**: Cargan datos desde Hive (almacenamiento local), no necesitan Firestore
- **Lista de sesiones**: Intenta cargar desde Firestore en modo online, requiere permisos

### Estructura de las Reglas

Las reglas de Firestore funcionan así:

1. **Autenticación requerida**: `request.auth != null`
   - Solo usuarios autenticados pueden acceder

2. **Verificación de propietario**: `request.auth.uid == userId`
   - Solo el propietario puede ver/modificar sus propios datos

3. **Permisos de lectura/escritura**:
   - `read` = `get` + `list` (leer documento individual + consultar colección)
   - `write` = `create` + `update` + `delete`

4. **Validación de datos**: En `create` y `update`
   - Verifica que los campos requeridos existan
   - Valida que el tipo sea 'Entrenamiento' o 'Competición'

### Ruta de Datos en Firestore

```
/users/{userId}                    <- Documento del usuario (perfil)
  /sesiones/{sesionId}             <- Subcolección de sesiones
    - fecha: DateTime (ISO8601)
    - lugar: String
    - tipo: String ('Entrenamiento' | 'Competición')
    - partidas: Array[Partida]
    - notas: String (opcional)
```

## Solución de Problemas

### El error persiste después de desplegar las reglas

1. **Cierra sesión y vuelve a iniciar sesión** en la app
   - El token de autenticación podría estar caducado

2. **Verifica que estás autenticado**:
   - Ve a Ajustes en la app
   - Verifica que aparece tu cuenta de Google
   - Si no aparece, inicia sesión

3. **Verifica en Firebase Console**:
   - Ve a **Authentication** y verifica que tu usuario existe
   - Ve a **Firestore Database** y verifica que existen las colecciones `users` y subcolecciones `sesiones`

4. **Verifica la estructura de datos**:
   - Cada sesión debe estar en `/users/{tu-uid}/sesiones/{sesion-id}`
   - No en la raíz de Firestore ni en otra ubicación

### Otros errores comunes

- **Error de red**: Verifica tu conexión a Internet
- **Error de configuración**: Verifica que Firebase esté configurado correctamente en `android/app/google-services.json`

## Recursos Adicionales

- [Documentación oficial de Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- Ver `AUTENTICACION.md` para más detalles sobre la arquitectura de autenticación
