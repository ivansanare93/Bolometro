# Prueba controlada del respaldo en la configuración actual

28 de octubre de 2026. Decisión del usuario: mantener Firebase
`bolometro-f216b` y applicationId `com.bolometro`. No crear flavors, otro proyecto
ni otra identidad Android. Esta guía sustituye la propuesta anterior de QA
separada. **El usuario ha autorizado habilitar el respaldo por defecto en el
código. No se ha generado ni distribuido una APK; la compilación sigue siendo
un paso independiente.**

## Qué está comprobado y qué falta

La configuración Android y `.firebaserc` apuntan al proyecto indicado. El código
inicializa Firebase con la configuración habitual. El archivo local de reglas
conserva el bloque del arsenal, su historial y las validaciones restauradas de
notificaciones. El texto seleccionado en el mensaje del IDE aún no contenía
estas dos condiciones de creación de notificaciones:

```text
request.resource.data.keys().hasAll(['type', 'createdAt', 'read'])
request.resource.data.read == false
```

No se ha leído la versión activa de Firebase Console: no hay herramienta
conectada de Firebase ni CLI autenticado disponible en esta sesión. La publicación
manual comunicada por el usuario no sustituye esa comprobación. Por tanto:

- Las reglas **locales** permiten el protocolo del motor: comprobado en emulador.
- Los 11 bloques de permisos previamente publicados se compararon, conservando
  sus condiciones; arsenal y gamificación son los bloques adicionales identificados.
- Que las reglas **activas** sean idénticas sigue pendiente de contrastar con el
  contenido de Console. No se afirma haber comprobado una publicación en vivo.

La huella SHA256 del archivo local revisado es:

```text
4DA82E7FCE8A027181D6CB3933423F81BABE9D9D84E89E457E0CAD84B35A422A
```

Antes de la prueba, seleccionar exactamente `bolometro-f216b`, comprobar la base
de datos utilizada por la app y comparar las reglas activas con `firestore.rules`,
incluidas las condiciones anteriores. Si difieren, detener la prueba y revisar
la diferencia. No publicar reglas desde esta tarea. La huella cambia con finales
de línea; una copia de Console también requiere comparación de contenido.

## Activación limitada a una compilación y a cuentas ficticias

Por petición posterior del usuario, el repositorio utiliza
`ARSENAL_BACKUP_ENABLED=true` como valor predeterminado. Las siguientes
compilaciones normales habilitan el respaldo para sus usuarios autenticados.
Las APK ya instaladas no cambian sin una actualización.
Se añadió un filtro opcional de UID para la compilación controlada:

| Configuración | Comportamiento |
| --- | --- |
| Sin bandera y sin lista de UID | Respaldo habilitado para los usuarios autenticados de esa compilación |
| `ARSENAL_BACKUP_ENABLED=false` | No respalda remotamente, aunque el UID esté permitido |
| Bandera `true`, sin `ARSENAL_BACKUP_TEST_UIDS` | Permite respaldo a las cuentas usadas en esa APK: no usar así para este ensayo |
| Bandera `true`, lista de UID definida | Solo respalda las cuentas cuyos UID figuran en la lista |
| Lista definida pero vacía | No habilita ninguna cuenta |

El filtro también se aplica a sincronizaciones automáticas al iniciar sesión o
guardar, a sincronizaciones generales y a los botones que consultan
`arsenalBackupEnabled`. Una cuenta excluida conserva su diario local y no activa
el respaldo del arsenal. No cambia la autenticación ni los permisos del servidor
y no limita otras funcionalidades de la app: no es una barrera de seguridad
frente a clientes modificados ni un apagado global.

Comando preparado, **no ejecutado**, para cuando el usuario confirme los riesgos
y se sustituyan los dos UID por los de las cuentas ficticias:

```powershell
flutter build apk --release --no-pub --dart-define=ARSENAL_BACKUP_ENABLED=true "--dart-define=ARSENAL_BACKUP_TEST_UIDS=UID_FICTICIO_A,UID_FICTICIO_B"
```

No escribir esos valores en `pubspec.yaml`, en el valor predeterminado ni en una
configuración de compilación compartida. Los UID no son contraseñas ni tokens.
La lista se incorpora a esa APK; no habilita retroactivamente versiones ya
instaladas. Para este ensayo la lista debe estar definida y no vacía.

Se revisará la disponibilidad de la firma original antes de compilar. No se
generará una clave sustituta ni se mostrarán contraseñas. La configuración Gradle
actual evalúa la firma release durante la configuración del proyecto.

## Conservación, primera sincronización y conflictos

La revisión y las pruebas controladas del motor confirman:

- Las entidades mantienen sus IDs. La cola se guarda en Hive antes de escribir
  el modelo; sus operaciones se recuperan al abrir de nuevo la cuenta.
- El motor no elimina documentos de bolas o mantenimientos. Las reglas locales
  prohíben el borrado de entidades e historial desde el cliente.
- La descarga incorpora registros por ID, sin vaciar las cajas del arsenal.
  Un registro pendiente o en conflicto no se reemplaza con la descarga.
- Si una bola local heredada tiene el mismo ID que una remota con contenido
  diferente, la revisión no coincide: se conserva el registro canónico y se
  guarda la propuesta en historial como conflicto. El usuario debe elegir.
- Repetir una operación confirmada no crea otra entidad. Si los payloads son
  idénticos, se puede reconocer el respaldo sin pedir una resolución innecesaria.
- No se usa el reloj del dispositivo para decidir qué versión gana. Las
  actualizaciones limpias ya sincronizadas sí pueden recibir automáticamente
  una revisión confirmada en otro cliente; no toda actualización normal pide
  confirmación manual. El historial respaldado conserva las versiones anteriores.
- Una ausencia remota inesperada produce error y conserva la copia local.

Después de una pérdida de red, la copia local y el diario permanecen. El reintento
ocurre al volver a iniciar sesión, guardar o pulsar sincronizar. Recuperar la red
por sí solo no garantiza un reintento inmediato y no hay servicio de respaldo
con la app cerrada. Un timeout no demuestra que el servidor no haya recibido el
commit: el mismo ID de operación permite reintentarlo sin duplicarlo.

Se comprobaron 78 pruebas del área afectada, incluidas las del filtro de UID,
activación por defecto y respaldo automático al iniciar sesión. También se
verificó por separado la desactivación real mediante
`--dart-define=ARSENAL_BACKUP_ENABLED=false`. El análisis estático de los archivos
afectados no encontró incidencias. Las 23 pruebas de seguridad
de las reglas locales ya superadas siguen como evidencia del emulador, no como
verificación de las reglas activas. No se han usado datos ni cuentas reales.

## Preparación de la cuenta y del dispositivo

1. Utilizar un emulador Android vacío o un segundo dispositivo sin datos reales.
   Con el mismo applicationId no se dispone de dos aplicaciones independientes
   instalables juntas. Un cambio de nombre de APK no aísla datos ni sesiones.
2. No instalar encima de la app habitual ni desinstalarla para resolver un error
   de firma. Un perfil secundario Android no garantiza una versión de APK
   independiente: el código del paquete puede compartirse entre perfiles.
3. Preparar dos cuentas ficticias A y B en el Firebase actual y anotar sus UID.
   Crearlas manualmente en Authentication o mediante el registro normal, sin
   usar cuentas habituales. No proporcionar sus contraseñas en el chat.
4. Confirmar que no tienen arsenal, sesiones ni notas reales. Usar datos como
   «TEST Arsenal A 01», notas «dato ficticio» y mantenimientos de prueba.
5. Proporcionar solo sus UID para incorporarlos al comando local. No importar
   copias ni exportaciones de usuarios reales.
6. Comparar las reglas activas antes de comenzar y comprobar que los UID de la
   prueba coinciden con las cuentas que se usarán en el dispositivo vacío.

No se ha creado una cuenta ficticia ni se ha escrito ningún documento en Firebase
durante esta preparación. Eso requiere el recorrido controlado posterior.

## Recorrido preparado

| Caso | Acción solo con datos ficticios | Resultado que debe verificarse |
| --- | --- | --- |
| Primera subida | En A, crear bola y mantenimiento; pulsar «Respaldar y recuperar arsenal» | Ambas entidades confirmadas, sin cambiar IDs |
| Logout | Salir y volver a A | Datos locales y mantenimiento conservados, sin duplicados |
| Error de red | Sin conexión, editar notas y añadir mantenimiento | Datos locales conservados; aviso pendiente/error, no éxito |
| Reconexión | Recuperar red y pulsar sincronizar | Misma entidad, nueva revisión cuando corresponda, sin duplicados |
| Recuperación | En otro emulador o dispositivo de prueba vacío, entrar en A | Recuperar lo confirmado con los mismos IDs |
| Aislamiento | Entrar en B | No mostrar ni descargar el arsenal de A |
| Conflicto | En dos clientes ficticios de A, editar la misma revisión sin conexión | Alternativas conservadas y elección explícita de usuario |
| Cambio durante petición | Cambiar A → B mientras termina una petición de A | Ningún resultado de A aplicado a B |
| Lista permitida | Probar un UID C adicional ficticio, excluido | Respaldo desactivado y ninguna operación remota del arsenal para C |

Las pruebas de conflicto y permisos negativos deben usar exclusivamente estos
UID ficticios. No intentar acceder a UID de terceros reales.

## Comprobación en Firebase Console

En el proyecto `bolometro-f216b`, anotar el UID de A en Authentication. En los
datos de Firestore buscar:

```text
users/UID_A/balls/ID_BOLA
users/UID_A/balls/ID_BOLA/revisions/ID_OPERACION
users/UID_A/ball_maintenance/ID_MANTENIMIENTO
users/UID_A/ball_maintenance/ID_MANTENIMIENTO/revisions/ID_OPERACION
```

Una subcolección puede existir aunque el documento padre no tenga campos. No
deducir ausencia del arsenal solo por el aspecto del documento padre `users`.

Para cada entidad comprobar:

- ID del documento, `id` y `payload.id` coincidentes con la entidad de prueba.
- En el mantenimiento, `payload.ballId` apunta a la bola ficticia esperada.
- `revision` positiva, `operationId` y la revisión de historial correspondiente.
- `kind: accepted` en el documento canónico.
- `updatedAt` del sobre asignado por el servidor. El `payload.updatedAt` del
  modelo es un campo diferente y no acredita por sí solo una subida nueva.
- Notas y demás valores del último cambio de la prueba realmente presentes.

Confirmación: en la app aparece «Respaldo confirmado en la última sincronización»
sin pendientes ni conflictos, después de responder el servidor. El adaptador
usa `Source.server`. Verificar bola **y** mantenimiento: que exista una versión
remota anterior no demuestra que el cambio más reciente esté subido.

Si hay contador pendiente, error, «Aún no hay respaldo confirmado» o conflicto,
no dar por protegidos todos los cambios. Un `kind: conflict` en historial guarda
una alternativa, no indica que se haya sustituido el registro canónico. Una
elección del usuario produce una nueva revisión cuando llega a confirmarse.

El diario `arsenal_sync_UID` y su `meta/confirmation` están en el dispositivo,
no en una colección de Console. Su fecha informativa no sustituye comprobar
payload, revisión y respuesta del servidor.

## Riesgos que deben aceptarse antes de compilar

1. Se utiliza el proyecto real: documentos ficticios consumen sus cuotas y las
   funcionalidades ajenas al arsenal también pueden escribir datos de prueba.
2. La APK tiene el mismo package. Puede actualizar una instalación habitual,
   reutilizar su sesión y acceder a sus cajas. Se requiere un dispositivo vacío.
3. El filtro limita este cliente y el arsenal, no todas las funcionalidades ni
   clientes ya instalados. No iniciar sesión con cuentas reales para este ensayo.
4. Las opciones generales `subirANube()` y `descargarDesdeNube()` conservan flujos
   heredados de reemplazo de sesiones/notas. No usarlas; utilizar solo el botón
   del arsenal y las cuentas ficticias. No se han ejecutado contra Firebase real.
5. Falta confirmar las reglas activas y realizar el recorrido SDK/dispositivo
   contra el servidor. Las pruebas del emulador no prueban esa configuración.
6. Una reinstalación nunca recupera un cambio que no llegó a respaldarse. No
   probar borrados, limpiezas o desinstalaciones con datos reales.

## Desactivación y vuelta atrás

No hay un interruptor remoto en la implementación actual. Antes de cualquier
otra acción, cerrar la APK de prueba o desconectarla. Una petición ya enviada
puede terminar; no asumir que se ha cancelado.

Preparar, solo con autorización, la misma app y firma con bandera explícita:

```powershell
flutter build apk --release --no-pub --dart-define=ARSENAL_BACKUP_ENABLED=false
```

Instalarla como actualización únicamente sobre la instalación de pruebas,
conservando datos y diario local. No desinstalar ni vaciar cajas para apagar el
respaldo. Las compilaciones habituales sin la bandera utilizan ahora el valor
predeterminado `true`; para desactivar hay que indicar `false`. Una nueva compilación no apaga otros APK activados:
detener o actualizar cada dispositivo de prueba. Conservar el historial remoto
para diagnóstico; no borrar documentos ni cambiar reglas de producción.

## Siguiente autorización

Antes de generar la APK hacen falta: confirmar estos riesgos, disponer de un
dispositivo de pruebas vacío, identificar los UID ficticios permitidos y
contrastar las reglas activas. No se ha realizado ninguna compilación con el
respaldo activado, despliegue, commit, push ni publicación en Google Play.
