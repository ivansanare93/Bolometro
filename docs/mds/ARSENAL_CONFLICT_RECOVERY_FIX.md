# Corrección de revisión de conflictos del arsenal

Fecha: 28-10-2026. Caso comunicado: «Bad state: Synchronize to retrieve the
remote conflict first» al elegir cuenta o dispositivo en «Mis bolas».

## Diagnóstico reproducido

`recover()` puede conservar una edición de una versión anterior de la app como
`legacyVariant` y marcar un conflicto local. En ese momento puede no existir
todavía `remotePayload`: hace falta sincronizar para recuperar la versión de la
cuenta y respaldar la variante local antes de descartar cualquiera de ellas.

La pantalla ofrecía las dos elecciones incluso con el respaldo desactivado,
sin recuperar antes esa versión remota. `resolve()` rechazaba correctamente
la elección incompleta, pero se mostraba su error técnico en inglés.
El primer test de regresión reprodujo este fallo antes del arreglo.

La captura muestra además el estado de respaldo desactivado. En este código el
valor predeterminado de `ARSENAL_BACKUP_ENABLED` ya es `true`; la captura no
identifica por sí sola el comando de compilación, versión instalada o posible
lista `ARSENAL_BACKUP_TEST_UIDS`. Las reglas publicadas no activan un flag que
esté desactivado dentro de una app ya compilada. No se han cambiado esos flags.

## Cambios

- `mis_bolas_screen.dart`: con respaldo desactivado se explica la limitación,
  sin ofrecer cuenta/dispositivo. Con respaldo habilitado se sincroniza antes
  del diálogo y se comprueba que existen ambas versiones conservadas. Un error
  de red permite reintentar sin realizar la elección. Se evitan pulsaciones
  simultáneas y se comprueba que sigue siendo la misma cuenta tras cada espera.
- `arsenal_sync_service.dart`: al leer el servidor se actualiza el lado remoto
  de los conflictos sin sustituir las copias locales. Una elección exige copia
  remota, revisión válida y respaldo de cualquier variante heredada.
- La pantalla pasa al servicio el conflicto que se mostró. Si cambia la copia
  local o remota mientras el diálogo está abierto, se exige revisarlo de nuevo;
  no se aplica silenciosamente una versión distinta a la presentada.
- Tras una elección explícita se refresca primero la lista local, incluso si
  el respaldo posterior vuelve a fallar. El cambio conserva su operación
  pendiente para reintentar. El control de revisiones existente sigue evitando
  sobrescribir sin conflicto una edición posterior de otro dispositivo.

No se cambia el esquema de Hive, los adaptadores, las reglas de Firestore,
colecciones, flags de respaldo, IDs ni datos de producción. No se borra un
conflicto por ocultarlo ni se elige automáticamente una versión. La preparación
usa la sincronización y el historial existentes de la cuenta, sin nuevas rutas
o permisos Firebase. El catálogo no cambia.

## Pruebas y alcance

Se añade `test/arsenal_conflict_screen_test.dart`, con seis casos:

1. Respaldo desactivado: no ofrece elecciones ni contacta con el servidor.
2. Conflicto sin snapshot remoto: sincroniza antes de elegir dispositivo.
3. El mismo conflicto permite elegir cuenta después de conservar ambas versiones.
4. Fallo de red: conserva las variantes y permite volver a revisar.
5. Cambio de cuenta durante la preparación: no muestra ni aplica opciones de la
   cuenta anterior a la nueva cuenta.
6. Cambio remoto mientras el diálogo está abierto: rechaza la elección obsoleta.

**145 pruebas superadas**, incluidas las regresiones de conservación del
arsenal, pantallas y catálogo. Análisis estático de los tres archivos del arreglo
sin incidencias. Todo se ejecuta con Hive temporal y servidor en memoria, sin
inicializar Firebase ni acceder a cuentas reales. La prueba de cambio de cuenta
usa esperas de red aisladas del reloj simulado de widgets.

```powershell
flutter test --no-pub test/arsenal_conflict_screen_test.dart test/arsenal_preservation_test.dart test/mis_bolas_screen_test.dart
flutter analyze --no-pub lib/services/arsenal_sync_service.dart lib/screens/mis_bolas_screen.dart test/arsenal_conflict_screen_test.dart
```

No se han verificado en vivo la configuración de la instalación de la captura,
sus datos remotos ni las reglas desplegadas. El arreglo local no demuestra que
esa instalación tenga el respaldo habilitado o acceso a Firebase.

## Cómo validar en la aplicación

Generar la nueva versión desde este workspace con la configuración habitual de
firma. Para hacer explícita la activación ya predeterminada del respaldo:

```powershell
flutter build apk --release --dart-define=ARSENAL_BACKUP_ENABLED=true
```

Si la ejecución del IDE o un archivo de defines incluye
`ARSENAL_BACKUP_TEST_UIDS`, comprobar que permite la cuenta de pruebas o retirar
esa restricción en la compilación que corresponda. **Una lista definida pero
vacía desactiva el respaldo para todas las cuentas**: no equivale a omitir el
parámetro. Un cambio de defines requiere volver a ejecutar/recompilar la app,
no solo hot reload. El catálogo continúa habilitado por defecto.

Instalar como actualización compatible, sin desinstalar ni borrar datos. Si el
estado sigue indicando respaldo desactivado, revisar la versión instalada y sus
defines antes de esperar una sincronización. No se ha generado ni instalado
una APK desde esta sesión.

Con una cuenta ficticia y conexión:

1. Abrir «Mis bolas» y pulsar «Revisar…».
2. Esperar a que se comprueben y conserven ambas versiones. Si falla, reintentar
   al recuperar la conexión; no borrar datos.
3. Revisar lo que muestra cuenta y dispositivo y elegir explícitamente.
4. Comprobar la bola seleccionada y que se confirma el respaldo o queda una
   operación pendiente de reintento. El historial conserva las otras versiones.

Con respaldo desactivado solo debe aparecer la explicación, sin las elecciones
que producían el error. No se despliegan reglas, ni se hace commit, push o
publicación.
