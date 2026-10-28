# Activación del respaldo del arsenal en una APK de pruebas

> Propuesta histórica sustituida por decisión explícita del usuario el
> 28 de octubre de 2026. No implementar el flavor ni el segundo proyecto de este
> documento. El plan vigente mantiene `bolometro-f216b` y `com.bolometro`:
> [Prueba controlada con la configuración actual](ARSENAL_CONTROLLED_ACTIVATION.md).

Revisión del 28 de octubre de 2026. Estado: **detenido antes de activar o
compilar por riesgo de compartir configuración con producción**. Este documento
es la propuesta para aprobación; los cambios de aislamiento todavía no están
implementados. No se ha generado una APK ni desplegado reglas.

## Configuración encontrada

| Elemento | Valor actual | Evidencia |
| --- | --- | --- |
| Proyecto Firebase Android | `bolometro-f216b` | `android/app/google-services.json`, `project_info.project_id` |
| Alias del CLI Firebase | `Bolometro` apunta a `bolometro-f216b` | `.firebaserc` |
| applicationId | `com.bolometro` | `android/app/build.gradle.kts`, `defaultConfig` |
| Registro Android de Firebase | `com.bolometro` | `client_info.android_client_info.package_name` |
| Configuración de pruebas independiente | No hay `productFlavors` ni `applicationIdSuffix` | Gradle actual |
| Inicialización Firebase | `Firebase.initializeApp()` sin opciones alternativas | `lib/main.dart` |
| Activación del respaldo | `const bool.fromEnvironment('ARSENAL_BACKUP_ENABLED')`, por defecto `false` | `lib/repositories/data_repository.dart:34` |

El proyecto coincide con el proyecto habitual documentado de Bolómetro. No hay
evidencia de aislamiento de Firebase en esta copia. Tampoco hay una APK local
en `build/app/outputs/flutter-apk` para inspeccionar. No se ha inspeccionado la
APK instalada en el teléfono; sus valores no pueden deducirse con certeza del
nombre que muestra Android.

Activar únicamente la bandera con esta configuración permitiría que la app
contactara con el proyecto habitual. La política de detención solicitada por el
usuario impide hacerlo antes de aprobar una solución de aislamiento.

## Reglas locales y publicación comunicada

El usuario ha comunicado la publicación manual. Esta revisión no ha leído las
reglas activas del servidor y no certifica que esa publicación coincida con el
archivo local. No hay una sesión de Firebase Console o CLI autenticado utilizada
para comprobarlo.

El archivo local `firestore.rules` contiene los contratos usados por el motor:

- `users/{uid}/balls/{ballId}`.
- `users/{uid}/ball_maintenance/{maintenanceId}`.
- `revisions/{operationId}` bajo cada registro.
- Lectura privada por UID, revisiones, transacciones e historial inmutable.
- Validaciones de notificaciones: presencia de `type`, `createdAt`, `read`, y
  `read == false` al crear, conservando los tipos publicados permitidos.

El texto seleccionado en el mensaje del IDE todavía omitía esas dos últimas
validaciones de notificaciones. Si refleja lo publicado, hay una diferencia que
debe comprobarse; no se ha sustituido el archivo local por esa selección antigua.
El archivo local actualizado debe conservarse al integrar cambios entre
workspaces. Sigue modificado sin commit; no se ha realizado ningún commit.

Huella del archivo local revisado, antes de cualquier publicación futura:

```text
SHA256 4DA82E7FCE8A027181D6CB3933423F81BABE9D9D84E89E457E0CAD84B35A422A
```

La huella corresponde a bytes concretos, incluidos finales de línea. Para
comparar un texto copiado desde Console, revisar también diferencias de formato
y las condiciones completas. No desplegar automáticamente una copia antigua
del workspace. No se han desplegado ni cambiado reglas en esta revisión.

## Solución propuesta para aprobación

1. Crear un flavor Android `arsenalQa`, con applicationId propuesto
   `com.bolometro.arsenalqa`, nombre visible «Bolómetro QA» y almacenamiento
   Android separado. La aplicación habitual conserva su identificador.
2. Usar un proyecto Firebase distinto, dedicado a datos ficticios. Ejemplo de
   nombre propuesto: `bolometro-arsenal-qa`; su existencia y disponibilidad no
   están verificadas. Se puede utilizar un proyecto QA ya existente, después de
   comprobar su identidad y que no contiene datos reales.
3. Registrar esa aplicación Android en el proyecto QA y colocar su configuración
   en `android/app/src/arsenalQa/google-services.json`. La configuración habitual
   no se reemplaza. Se revisarán Auth, Firestore y el resto de SDKs de Firebase
   para que tampoco utilicen producción desde QA.
4. Añadir validaciones de compilación: el flavor QA debe rechazar el proyecto
   `bolometro-f216b`, una configuración ausente o un package distinto del esperado.
   Añadir además una comprobación al iniciar antes de permitir sincronización.
5. Habilitar la bandera únicamente para la compilación QA, manteniendo `false`
   como valor predeterminado. Una compilación habitual no debe aceptar por error
   la activación remota del experimento.
6. Generar una APK **debug de QA**, firmada para pruebas, instalable junto a la
   habitual. Revisar la configuración Gradle de firma para que QA no dependa de
   credenciales privadas release. No sustituir la clave de la aplicación publicada.
7. Verificar los metadatos de la APK generada y la configuración Firebase antes
   de entregarla. No instalar encima de la app que contiene datos reales.

No se ha creado un proyecto Firebase, registrado una app ni activado ningún
servicio. La preparación de Auth/Firestore QA y cualquier publicación manual de
sus reglas corresponden a pasos explícitos posteriores. El agente no desplegará
reglas, ni siquiera a QA, bajo la restricción actual.

## Comprobación de la sincronización inicial

Revisión del código y pruebas existentes:

- El diario local detecta registros heredados sin modificar sus IDs. La escritura
  remota usa transacciones y compara la revisión base, sin elegir por el reloj
  del dispositivo.
- Un mismo ID inicial con contenido remoto diferente se trata como conflicto:
  no se sustituye silenciosamente la versión canónica y la propuesta se guarda
  en historial. El usuario elige la versión que quiere utilizar.
- La descarga incorpora registros por ID sin vaciar las cajas del arsenal. Los
  cambios pendientes y conflictos locales no se reemplazan por la descarga.
- Un registro previamente respaldado ausente en el servidor produce error y
  conserva la copia local. Una respuesta vacía no se interpreta como borrado.
- Para un registro limpio y ya sincronizado, una revisión confirmada en otro
  dispositivo puede actualizar la copia local automáticamente. No se solicita
  confirmación manual en cada actualización normal; las revisiones respaldadas
  conservan el historial. Estas garantías no sustituyen las pruebas en dispositivo.

Usar el botón **«Respaldar y recuperar arsenal»** durante la validación. No usar
las opciones globales de sobrescritura: el método heredado `subirANube()` elimina
sesiones y notas remotas para reemplazarlas, y `descargarDesdeNube()` reconstruye
esas cajas locales. Su existencia refuerza la necesidad de aislar el proyecto
completo, no solo las dos colecciones del arsenal. No se ejecutaron esos métodos
contra un servidor real.

## Resultados recuperados, sin repetir pruebas correctas

En la revisión inmediatamente anterior a la interrupción se completaron:

- **73/73 pruebas del área del arsenal** con Hive temporal y servicios ficticios.
- **23/23 pruebas de reglas** en Firestore Emulator, proyecto ficticio
  `demo-bolometro-arsenal`, endpoint `127.0.0.1:8787`.
- No se accedió a Firestore de producción ni se usaron cuentas reales.

Incluyen cierre de sesión, aislamiento, restauración sobre almacenamiento vacío,
cola offline, fallo de red, pérdida de acuse tras commit, conflictos, importación
explícita, cambios de cuenta durante peticiones y conservación de IDs. Las reglas
comprueban permisos de propietario/otra cuenta/no autenticado, revisiones,
historial, notificaciones y gamificación.

No se repitieron al retomar la tarea. La conexión real SDK Flutter → Firebase QA
y la APK instalada siguen pendientes de aislamiento y aprobación.

## Verificación manual en Firebase Console, solo después de aislar QA

1. Seleccionar el proyecto QA y comprobar su **Project ID** en la configuración
   del proyecto. No basta con que el nombre visible contenga «pruebas».
2. Crear dos usuarios ficticios A y B en Authentication y anotar sus UID. No
   reutilizar la cuenta habitual con registros reales.
3. Iniciar sesión en QA con A. Crear «QA Bola 01» y un mantenimiento ficticio.
4. Pulsar «Respaldar y recuperar arsenal» y comprobar el resultado en la app.
5. En los datos de Firestore, revisar las rutas `users/UID_A/balls` y
   `users/UID_A/ball_maintenance`. Que exista o no un documento padre en `users`
   no determina por sí solo la existencia de sus subcolecciones.
6. Verificar estos campos en cada documento:

| Campo | Resultado esperado |
| --- | --- |
| ID del documento, `id`, `payload.id` | Mismo identificador local de la entidad |
| `payload.ballId` del mantenimiento | ID de la bola correspondiente |
| `revision` | Entero positivo; aumenta en ediciones aceptadas |
| `operationId` | Identifica la operación respaldada |
| `kind` canónico | `accepted` |
| `updatedAt` del sobre | Timestamp asignado por el servidor |
| `revisions/{operationId}` | Versión correspondiente, con payload y revisión |

Un documento `kind: conflict` en historial conserva una alternativa; no significa
que esa alternativa haya reemplazado el registro canónico. El `updatedAt` dentro
de `payload` es un dato del modelo, distinto del timestamp del sobre remoto.

### Confirmado frente a pendiente

- La app debe mostrar «Respaldo confirmado en la última sincronización», sin
  pendientes ni conflictos, después de una respuesta del servidor. El adaptador
  utiliza `Source.server`, no confirma a partir de una caché.
- La aparición de solo una bola en Console no prueba que también se haya subido
  su mantenimiento. Comprobar ambas entidades y sus IDs/revisiones.
- Si aparece «Respaldo pendiente», «Aún no hay respaldo confirmado», un contador
  de pendientes o un conflicto, no considerar protegidos todos los cambios.
- Un registro remoto anterior puede existir aunque falle una edición nueva;
  contrastar el payload y la revisión del cambio que se está probando.
- El diario `arsenal_sync_UID` y `meta/confirmation` son datos locales. Su fecha
  informativa no sustituye una confirmación del servidor ni es una colección
  que deba buscarse en Firebase Console.

## Recorrido manual preparado

Solo sobre la futura app QA, con datos ficticios y tras comprobar el aislamiento:

| Caso | Acción | Criterio de aceptación |
| --- | --- | --- |
| Primera subida | Crear bola y mantenimiento, sincronizar | Dos documentos e historial; IDs coincidentes y estado confirmado |
| Logout | Salir y volver a A | Bola y mantenimiento conservados, sin duplicados |
| Sin conexión | Quitar red, editar notas y añadir mantenimiento | Cambios locales conservados y estado pendiente/error; no anunciar éxito |
| Reconexión | Recuperar red y pulsar sincronizar | Cambios confirmados, sin duplicar registros ni revisiones por reintento |
| Recuperación | Usar otra instalación/dispositivo QA vacío y entrar en A | Recuperar las entidades previamente confirmadas con los mismos IDs |
| Aislamiento | Entrar en B | No mostrar ni descargar el arsenal de A |
| Cuenta durante petición | Cambiar A → B durante una petición de A | No aplicar el resultado de A a las cajas o UI de B |
| Conflicto | Editar el mismo ID desde dos clientes QA | Conservar alternativas y pedir resolución; no aumentar cobertura a costa de datos |

No desinstalar ni borrar datos de la app habitual. Una recuperación se puede
probar primero en otro dispositivo QA para no destruir ninguna copia existente.
Solo se recupera lo que ya recibió confirmación remota.

## Desactivar si aparece un problema

La bandera actual es de compilación, no un interruptor remoto. No existe un
apagado global por Firebase Remote Config en esta implementación.

1. Cerrar la app QA o quitarle conectividad para frenar nuevas peticiones. Una
   petición ya enviada puede haber sido confirmada; no asumir cancelación.
2. Preparar la misma variante QA con `ARSENAL_BACKUP_ENABLED=false` e instalarla
   como actualización, conservando applicationId y firma. No desinstalar ni
   limpiar sus datos: el diario y las copias locales deben permanecer.
3. Conservar las revisiones del servidor y los errores observados para diagnóstico.
   No borrar documentos ni vaciar cajas para hacer desaparecer el problema.
4. La app habitual y sus usuarios no necesitan cambios si el aislamiento se
   implementa correctamente. Cambiar una bandera local no desactiva APK ya
   instaladas en otros dispositivos; cada cliente QA debe detenerse/actualizarse.

No cambiar reglas de producción como medida de apagado dentro de esta tarea.

## Aprobación necesaria

Se requiere aprobar la configuración del flavor `arsenalQa` y su conexión a un
proyecto Firebase QA separado antes de implementar la activación o compilar.
Si ya existe ese proyecto, identificarlo y proporcionar su configuración Android
QA para verificarla. Si no existe, acordar su preparación sin modificar ni usar
datos de `bolometro-f216b`. No se solicita autorización para despliegues ni para
publicar en Google Play.
