# Conservación del arsenal — fase A

Estado: implementación local completa y probada. El usuario aprobó el diseño,
la migración explícita y las pruebas locales, sin autorizar despliegues.
El respaldo remoto está desactivado por defecto hasta autorizar reglas y
activación. No existe protección real frente a reinstalaciones hasta entonces.
Las pruebas usan dobles de servicio y un emulador local; no producción.

## Reproducción antes de corregir

El 27 de octubre de 2026 se ejecutó `test/arsenal_preservation_test.dart` antes
de modificar el comportamiento de conservación. Las únicas modificaciones de
producción necesarias para probarlo fueron inyectar `FirestoreService` y diferir
su acceso a `FirebaseFirestore.instance`. No se inicializa Firebase en el doble.

Resultado: 7/7 reproducciones confirmadas con un directorio temporal nuevo por
caso, sin usar almacenamiento real de la app:

1. Crear bola y mantenimiento con IDs fijos, `setUser('account-a')`,
   `clearUserData()`, salir y volver a entrar: ambas listas vacías.
2. Crear ambos registros como invitado e iniciar sesión: el destino queda vacío
   y la copia invitada permanece. Error real observado:
   `HiveError: The same instance of an HiveObject cannot be stored in two different boxes.`
3. Cambiar de A a B sin limpiar: B no ve los datos; volver a A los recupera.
4. `sincronizarANube()`: termina sin respaldar bolas ni mantenimientos.
5. `subirANube()`: mismo resultado.
6. `descargarDesdeNube()`: mismo resultado.
7. Error de red simulado: se propaga y el arsenal local permanece intacto.

Las pruebas de eliminación se convirtieron en regresión de conservación después
de la corrección. Las tres operaciones de sincronización ahora incluyen el
arsenal cuando se activa expresamente el respaldo remoto.

## Protección local

`clearUserData()` debe cerrar las cajas de la cuenta sin borrarlas. Se preservan
también sesiones, perfil y notas: cualquiera podría tener cambios no subidos o
referencias a las bolas. El modo invitado y cada UID siguen usando sus nombres
de caja existentes. No hay cambios de modelos, adaptadores, IDs ni formatos.
La salida de la cuenta desconecta el repositorio de sus cajas; conservar archivos
privados no significa mostrarlos al siguiente usuario. Eliminar la cuenta o
solicitar expresamente borrar datos es una operación diferente del logout.

El selector distingue cancelar de elegir explícitamente «Sin especificar».

## Diseño aprobado e implementado

### 1. Reglas y respaldo remoto

Las reglas originales no autorizaban subcolecciones de arsenal. No se ha
comprobado su correspondencia con producción. No se guarda el arsenal en el
documento raíz del perfil como atajo: actualmente otros usuarios autenticados
pueden leer ese documento.

Rutas privadas, sin modificar los permisos de otras funcionalidades:

- `users/{uid}/balls/{ballId}`
- `users/{uid}/ball_maintenance/{maintenanceId}`
- Historial inmutable de revisiones de cada entidad, también bajo su UID.

Solo el propietario autenticado puede leer y escribir. Las reglas locales
validan ID de ruta, esquema, campos permitidos, referencias y revisiones. Sin
borrado físico desde el cliente; archivar sigue siendo un cambio de estado.
Las reglas se probaron en el emulador Firestore 1.22.0 con usuarios ficticios.
Ningún despliegue está autorizado.

Protocolo implementado:

1. Mantener Hive como copia local compatible y una caja auxiliar por UID para
   revisiones confirmadas, operaciones pendientes y conflictos. No cambiar
   `typeId` 19/20 ni campos existentes.
2. Guardar una operación durable con payload e ID estable antes de confirmarla
   al usuario; permitir reintentos y recuperación tras interrupciones.
3. Usar IDs actuales como claves remotas: no deduplicar por nombre ni generar
   otros IDs para entidades existentes. Dos bolas iguales pueden ser unidades
   físicas distintas.
4. Comparar revisión base con la revisión remota en una transacción. Reintentar
   una operación ya confirmada debe ser idempotente. No resolver por reloj del
   dispositivo ni sobrescribir con una descarga completa.
5. Si dos dispositivos editan la misma revisión, conservar ambas versiones y
   señalar conflicto; no elegir un ganador silenciosamente. Preservar un
   historial de revisiones permite recuperar valores anteriores legítimos.
6. Capturar UID y generación de sesión al iniciar cada operación. Cambiar de
   cuenta invalida su aplicación a la UI actual; nunca redirige una operación
   pendiente de A a las cajas o rutas de B.
7. Descargar e incorporar registros por ID sin vaciar cajas. Los cambios locales
   pendientes no se pisan; la falta de un registro remoto no implica borrarlo.
8. Exponer estado pendiente/confirmado/error/conflicto. Recuperar tras reinstalar
   solo será posible para registros cuya copia remota haya sido confirmada.

Las versiones anteriores leerán los mismos modelos Hive. Sus modificaciones
locales deberán detectarse comparando payloads con la última revisión conocida;
no debe dependerse únicamente de que escriban en la nueva cola. Una versión
antigua seguirá teniendo su antiguo logout destructivo: no puede corregirse
retroactivamente y no ofrece las garantías de la versión nueva.

### 2. Propiedad de los datos de invitado

No basta con copiar objetos para corregir la migración: el origen invitado queda
en disco y podría importarse posteriormente en otra cuenta. No hay actualmente
prueba de qué cuenta es su propietaria.

La pantalla muestra la cantidad de bolas invitadas y pide confirmación explícita
para la cuenta actual. Se guarda la atribución por ID en metadatos
separados, sin borrar la copia invitada. Copiar objetos nuevos (no instancias
adjuntas a Hive), por ID, incorporando solo ausentes. Si el mismo ID tiene
contenido diferente, conservar ambos payloads como conflicto y no sobrescribir.
Los mantenimientos y partidas vinculadas se revisan conjuntamente. Se conservan
IDs de bolas/mantenimientos y fechas identificadoras de sesiones; no se cambia
`Partida.ballId`. Las sesiones se copian con `copyWith`, sin normalizar sus frames
mediante `fromJson`. Las importaciones se serializan en el proceso para impedir
que dos cuentas atribuyan el mismo dato simultáneamente.

Las bolas ya atribuidas a otra cuenta no se ofrecen para importar. Una colisión
de IDs con contenido diferente aborta sin sobrescribir: ambas copias quedan
disponibles en sus cajas originales. No se fuerza una resolución automática.
Las sesiones mixtas que referencian bolas fuera del conjunto importable se
mantienen en origen; requieren revisión manual y no se anuncian como respaldadas.

La copia invitada original se conserva en el almacenamiento del dispositivo.
La atribución evita importarla en otra cuenta, pero no cifra los archivos ni
convierte el modo invitado en una sesión privada autenticada.

### 3. Estado, conflictos e historial

«Mis bolas» muestra solo almacenamiento local, cambios pendientes, error,
sincronización, confirmación o conflicto según corresponda. Hay acciones para
importar invitado, respaldar/recuperar y resolver conflictos. En el detalle de
bolas y mantenimientos se puede consultar el historial remoto y restaurar una
versión como nueva revisión del mismo ID. No se permite restaurar encima de
cambios locales pendientes sin respaldarlos antes.

La confirmación requiere respuestas del servidor (`Source.server`) y ninguna
ausencia inesperada de registros previamente confirmados. Una caché de Firestore
o una lista remota vacía no constituyen prueba de respaldo.

Los reintentos se producen al iniciar sesión o guardar, si está activado el
respaldo, y mediante el botón de sincronización. No hay detección automática de
conectividad ni servicio de sincronización en segundo plano con la app cerrada.
Errores y timeouts conservan el diario; un commit sin acuse se reintenta con el
mismo ID de operación. Cambios de versiones antiguas se detectan por contenido.

## Validación reproducible

Desde la raíz, con las dependencias fijadas ya resueltas:

```powershell
flutter test --no-pub test/arsenal_preservation_test.dart test/seleccionar_bola_field_test.dart test/data_repository_ball_test.dart test/bowling_ball_model_test.dart test/ball_stats_service_test.dart test/mis_bolas_screen_test.dart test/data_repository_test.dart
```

Las pruebas nuevas generan cajas en directorios temporales únicos. No cambies
`Hive.init()` para apuntar a carpetas reales, no desinstales la aplicación y no
uses cuentas de producción para validar estos cambios.

Reglas con el emulador ya instalado, en una terminal independiente:

```powershell
$arsenalEmulatorJar = Join-Path $env:USERPROFILE '.cache/firebase/emulators/cloud-firestore-emulator-v1.22.0.jar'
java -jar $arsenalEmulatorJar --host 127.0.0.1 --port 8787 --project_id demo-bolometro-arsenal --rules firestore.rules
```

Y, en otra terminal:

```powershell
node --test test/firestore_arsenal_rules_test.cjs
```

Node usa únicamente módulos incorporados. La URL es fija, local y de un proyecto
`demo-`; no hay credenciales reales. No se instalaron dependencias nuevas.
Se resolvieron desde caché las dependencias ya fijadas en `pubspec.lock`, usando
`flutter pub get --offline --enforce-lockfile`; no se modificó ese lockfile.

Resultados del 27 de octubre de 2026:

- 7 reproducciones iniciales confirmaron los problemas antes de corregirlos.
- 28 casos específicos del motor/conservación superados.
- 73 casos de regresión del área afectada superados, incluidos selector y
  aislamiento del listado, edición y detalle tras cambiar de cuenta.
- 11 pruebas reales de reglas superadas en el emulador: propietario, otra cuenta,
  no autenticado, historial inmutable, borrado prohibido, revisión obsoleta,
  conflicto conservado, escritura sin historial, payload inválido y referencias.
- Análisis estático: sin errores ni incidencias nuevas. Al incluir también
  `firestore_service.dart` aparece un aviso previo `unnecessary_cast` en la línea
  414, fuera de las líneas modificadas; no se ha cambiado ese código.
- Suite general: 349 superadas, 14 fallidas. Se reprodujeron esos mismos 14 fallos
  en una copia temporal de HEAD, sin cambios de esta fase. Afectan a
  `achievement_service_reset_test`, `analytics_service_test`,
  `estadisticas_cache_test`, `sesion_card_widget_test`, `theme_provider_test` y
  `utils/compartir_sesion_test`. No se han corregido áreas ajenas al alcance.
- Logs locales: `build/arsenal-validation/arsenal-tests.log`,
  `flutter-tests.log` y `baseline-failures.log`. La copia original de contraste
  está en `build/arsenal-validation/baseline` y no altera el árbol de trabajo.

## Activación pendiente, sin autorización de despliegue

La bandera de compilación `ARSENAL_BACKUP_ENABLED` vale `false` por defecto.
Sin activarla se conservan datos y diario local, se puede importar invitado y
las sincronizaciones existentes de otras funcionalidades no dependen de las
nuevas reglas. No se muestra un respaldo remoto confirmado ni se habilita su
botón. Las pruebas activan la opción solo con el servidor simulado inyectado.

Antes de activarla en una app real:

1. Configurar un proyecto y cuentas de pruebas separados; no reutilizar el
   proyecto actual de producción para validar borrados/reinstalaciones.
2. Probar en un dispositivo Flutter la integración SDK → emulador/proyecto de
   pruebas: las pruebas REST de reglas y los dobles no sustituyen ese recorrido.
3. Revisar y autorizar expresamente el despliegue de `firestore.rules`.
4. Autorizar una compilación con la bandera activada y confirmar un respaldo
   antes de probar recuperación en almacenamiento vacío de una instalación de
   pruebas. Nunca desinstalar la instalación que contiene la única copia real.

No se han ejecutado los pasos de activación ni cambiado configuraciones reales.

## Límites y riesgos restantes

- Con la bandera desactivada se conservan archivos en logout, pero no se crea
  respaldo fuera del dispositivo. El motor remoto está implementado y probado
  localmente; no está activado en producción.
- Una reinstalación, pérdida del dispositivo o borrado manual puede eliminar la
  única copia hasta implementar y confirmar el respaldo remoto.
- No repara automáticamente datos perdidos por cierres de sesión anteriores.
- Los datos de invitado y cambios offline no confirmados solo están en el
  dispositivo; una reinstalación no puede recuperar lo que nunca se subió.
- El historial remoto crece con las ediciones. No hay limpieza automática de
  revisiones ni política nueva de eliminación de cuentas; requiere definir una
  retención sin destruir la única copia. Cada edición aceptada escribe registro
  e historial; las lecturas/almacenamiento consumen cuotas del proyecto.
- No hay cifrado añadido a Hive ni protección frente al acceso al sistema de
  archivos de un dispositivo comprometido.
- Una versión antigua sigue ejecutando su logout anterior; la compatibilidad
  de archivos no puede corregir su comportamiento retroactivamente.
- Si un cliente antiguo acumula varias variantes diferentes sin confirmar
  mientras hay una escritura interrumpida, se bloquea la sincronización de esa
  sesión y se conservan las copias locales para recuperación manual.
- Prueba manual en dispositivo y activación/despliegue siguen pendientes.
- No se añadieron paquetes, catálogo, imágenes, commits ni despliegues.

## Archivos de esta entrega

| Área | Archivos |
| --- | --- |
| Persistencia e integración | `lib/repositories/data_repository.dart`, `lib/services/firestore_service.dart` |
| Motor y adaptador nuevos | `lib/services/arsenal_sync_service.dart`, `lib/services/arsenal_remote_store.dart` |
| Interfaz | `lib/screens/mis_bolas_screen.dart`, `lib/screens/detalle_bola_screen.dart`, `lib/screens/editar_bola_screen.dart`, `lib/widgets/seleccionar_bola_field.dart` |
| Historial nuevo | `lib/widgets/arsenal_history_button.dart` |
| Nuevas pruebas | `test/arsenal_preservation_test.dart`, `test/firestore_arsenal_rules_test.cjs`, `test/support/memory_arsenal_store.dart`, `test/support/test_firestore_service.dart` |
| Pruebas existentes adaptadas | `test/data_repository_test.dart`, `test/mis_bolas_screen_test.dart`, `test/seleccionar_bola_field_test.dart` |
| Seguridad y documentación | `firestore.rules`, `docs/mds/ARSENAL_PRESERVATION.md` |

No se modificaron modelos/adaptadores de Hive, `pubspec.yaml`, `pubspec.lock` ni
configuración de producción. Se restauraron los registrantes de plugins que
Flutter regeneró automáticamente, para no incluir cambios ajenos a esta fase.
