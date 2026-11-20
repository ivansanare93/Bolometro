# Fase C3 — validación final e integración local

> **Histórico, sustituido:** el usuario ha retirado el punto de entrada alternativo.
> La implementación actual y sus comandos están en
> [BALL_CATALOG_PHASE_C3_RELEASE.md](BALL_CATALOG_PHASE_C3_RELEASE.md).
> Los comandos de depuración de este documento ya no se utilizan.

Fecha: **28-10-2026**. Resultado: integración de prueba preparada, sin activación
del catálogo comercial para la app normal. No hay cambios en Firebase, respaldo,
modelos personales, adaptadores Hive ni identificador Android.

## Resultado sobre los datos

Se conserva el JSON C2 original, con `schemaVersion: 1`, versión de contenido 2,
28 modelos reales, **134 filas por peso**, 134 pares RG/DIFF conocidos y 75 valores
intermedios publicados. Los otros 59 intermedios permanecen nulos; no son ceros.
Los 30 candidatos siguen clasificados como **3 listos técnicamente, 25 con
campos desconocidos y 2 bloqueados**. Esta clasificación no es autorización de
redistribución ni prueba de disponibilidad comercial en vivo.

- Parser v1 y validador editorial: compatibles; sin IDs comerciales repetidos,
  pares fabricante/modelo duplicados ni pesos repetidos dentro de un modelo.
- Se enumeró una referencia de regresión de las tablas oficiales documentadas
  en C2, en `test/support/catalog_weight_reference.dart`. Se comparan las
  134 filas por ID y peso, incluidos los nulos. No se genera esta referencia
  leyendo el JSON durante el test: detecta cambios de peso, decimales y copia
  accidental de cifras de 15 lb. No sustituye una futura corrección del fabricante.
- Cada valor no nulo conserva procedencia y fecha editorial. Se verifican las
  referencias de fuentes, unidades en pulgadas, dominios y coherencia numérica.
- **IDOL y BVP Sidewinder siguen excluidos**. No se modifica su expediente ni
  se reutilizan sus IDs para otra bola. Las dudas de acabado de C2 siguen abiertas.
- Se conserva `photo: null` en los 28. La ficha usa la alternativa visual,
  sin peticiones de imágenes ni recursos gráficos de terceros.

Cobertura: 24 modelos tienen cinco filas 12–16 lb, Arctic Vibe siete filas
10–16 lb, Phaze III y Phaze V solo tres filas 14–16 lb y Hyper Venom únicamente
15 lb. No se afirma que esos subconjuntos agoten todas las variantes históricas.

Huella SHA-256 del snapshot revisado, para identificar exactamente este piloto:

```text
1A80820461410F697EE0CDFB5F2EE82532B5494C7092DED501909648C65404E0
```

## Campos desconocidos y comportamiento de las fichas

Las pruebas de widgets abren los **28 modelos**, seleccionan sus **134 pesos** y
comprueban RG, diferencial, intermedio y núcleo, además de año, cubierta,
acabado y estado. Antes de seleccionar peso no se muestran métricas por defecto.
Se comprueba que el desplegable contiene exactamente los pesos documentados.
No se interpreta que un peso no listado sea imposible: para una unidad no
cubierta sigue disponible la entrada manual.

| Modelo incompleto | Carencias principales | Presentación verificada |
| --- | --- | --- |
| Brunswick · Beyond Infinity | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Brunswick · Combat Solid | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Brunswick · Endeavor | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Brunswick · Infinity Quest Pearl | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Brunswick · Ultimate Defender | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Hammer · Arctic Vibe | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Hammer · Black Widow 3.0 | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Hammer · Full Effect | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Hammer · Hammer Effect | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Hammer · Maximum Effect | Estado comercial, Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Hammer · True Blood | Año, Estado comercial, Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| MOTIV · Black Venom | Año, Estado comercial | No disponible / Desconocido; sin completar por analogía |
| MOTIV · Covert Revolt | Año, Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| MOTIV · Hyper Venom | Año, Estado comercial, Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| MOTIV · Venom Recoil | Año, Tipo de cubierta | No disponible / Desconocido; sin completar por analogía |
| MOTIV · Venom Shock | Estado comercial | No disponible / Desconocido; sin completar por analogía |
| MOTIV · Venom Shock Pearl | Año, Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Roto Grip · Attention Star | Estado comercial, Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Roto Grip · Magic Gem | Estado comercial, Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Roto Grip · Perfect Gem | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Roto Grip · RST Hyperdrive Pearl | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Roto Grip · Transformer | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Storm · Hy-Road | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Storm · Phaze II | Núcleo según peso | No disponible / Desconocido; sin completar por analogía |
| Storm · Phaze V | Estado comercial, Acabado | No disponible / Desconocido; sin completar por analogía |

Un nombre de núcleo global nulo puede ser intencionado: existen nombres por
peso en 14–16 lb, pero no se propagan a pesos bajos sin prueba. Al seleccionar
un peso con núcleo desconocido la interfaz muestra «No disponible».
Los 59 intermedios sin fuente también muestran «No disponible», no 0.
El año desconocido no se convierte en 0 y el estado desconocido no se convierte
en «Actual» o «Descatalogada».

Se comprobó también el formulario personal con Phaze V: el acabado nulo deja
el campo vacío y se guarda como nulo si el usuario no lo introduce. La precarga
no inventa un valor. El usuario puede editar los campos personales habituales.

## Revisión específica de MOTIV

Se volvió a consultar la evidencia oficial disponible durante C3. No se modifica
la fecha de verificación del snapshot C2 por el mero hecho de ejecutar tests.
No se confunden resultados indexados con verificación en vivo del fabricante.

| Modelo | Evidencia consultada en C3 | Límite pendiente |
| --- | --- | --- |
| [Black Venom](https://www.motivbowling.com/products/balls/light-medium-oil/black-venom.html) | Tabla de página oficial accesible, cinco pesos e intermedios; 15 lb RG 2.47 | Año y estado desconocidos. No se usa el .247 del índice del PDF. |
| [Venom Shock Pearl](https://www.motivbowling.com/products/balls/retired-balls/venom-shock-pearl.html) | Tabla de página oficial accesible, cinco pesos; DIFF .035 a 15 lb | No usar .034 de la reseña. Año, tipo de núcleo e intermedio desconocidos. |
| [Venom Shock](https://www.motivbowling.com/shop/venom-shock.html) | Resultado indexado oficial con tabla 12–16 lb | No confirma disponibilidad actual. Se ignora el párrafo que nombra Hyper Venom. |
| [Venom Recoil](https://www.motivbowling.com/products/balls/retired-balls/venom-recoil.html?page=1) | Resultado indexado oficial con tabla y retirada | Año de lanzamiento y tipo específico de cubierta sin verificar. |
| [Covert Revolt](https://www.motivbowling.com/products/balls/retired-balls/covert-revolt.html) | Resultado indexado oficial con cinco filas | Año y simetría no confirmados; no se deducen del nombre Vanquish. |
| [Hyper Venom](https://www.motivbowling.com/userfiles/filemanager/dxx22yeosycufrut6yih) | Texto indexado del sell sheet oficial | Solo ofrece explícitamente 15 lb 2.48/.034. No se completan otros pesos, lanzamiento o simetría. |

Estas consultas no resolvieron todas las carencias. Antes de distribución general
conviene obtener documentación oficial accesible o confirmación del fabricante
para los cuatro modelos basados en índices, o aprobar expresamente su inclusión
parcial indicando esta limitación. El índice del buscador no es una licencia.
No se automatizó scraping, se eludieron bloqueos o se descargaron fotografías.

## Integración local preparada

La entrada normal `lib/main.dart` continúa creando el repositorio normal por
defecto. Solo admite una fábrica alternativa cuando se llama explícitamente a
`startBolometro` desde otro punto de entrada, y la rechaza fuera de debug.
No se añade un flavor, un interruptor de producción ni una URL remota.

`LocalReviewCatalogRepository` mantiene el snapshot en memoria, no abre Hive,
no escribe la caché comercial, no descarga actualizaciones y rechaza instalar
otro snapshot. Los tests comprueban que volver al repositorio normal sigue
mostrando su seed vacío. El demo ficticio permanece separado.

La herramienta `tool/catalog/prepare_local_review.dart`:

1. Valida el JSON y el expediente C2 con las puertas de aprobación cerradas.
2. Genera `.dart_tool/catalog_review/main.dart` con los datos revisados embebidos
   en el código del punto de entrada local. No copia datos a los assets.
3. No ejecuta Flutter, Firebase, Hive ni la app. Solo prepara el archivo local.

El archivo generado está ignorado por Git; el punto de entrada normal no lo
importa. **Los datos sí forman parte de un bundle de revisión compilado usando
ese punto de entrada**: no debe distribuirse ese bundle ni una eventual APK de
pruebas como versión pública. El JSON real sigue fuera de `pubspec.yaml`.

La lista y las fichas de revisión muestran un aviso visible. Antes de ir al
formulario desde una ficha real aparece una confirmación: guardar crea una bola
personal que podría sincronizarse con la cuenta conectada. Cancelar no modifica
el arsenal. La opción «Añadir manualmente» se mantiene.

Archivos de C3:

- `lib/main.dart`: punto de inicialización con inyección opcional solo debug.
- `lib/repositories/ball_catalog_repository.dart`: indicador de revisión,
  desactivado en el repositorio normal.
- `lib/repositories/local_review_catalog_repository.dart`: repositorio local
  de solo lectura, sin caché comercial.
- `lib/screens/ball_catalog_screen.dart` y
  `lib/screens/catalog_ball_detail_screen.dart`: avisos y confirmación de revisión.
- `tool/catalog/prepare_local_review.dart`: generador del punto de entrada.
- `test/catalog_c3_local_test.dart`, `test/support/catalog_weight_reference.dart`
  y ampliación de `test/catalog_flow_test.dart`: datos, UI y conservación.
- Este informe. El archivo generado y el bundle permanecen en directorios
  ignorados; no forman parte de la configuración de assets normal.

Los cambios previos de B/C1/C2 se conservan. Que `pubspec.yaml` u otros archivos
anteriores sigan apareciendo modificados en Git no indica cambios nuevos de C3.

## Cómo probar y volver a la entrada normal

Utilizar **emulador, dispositivo o perfil Android de pruebas** y una cuenta
ficticia o invitado nuevo. Se mantienen `com.bolometro` y Firebase
`bolometro-f216b`: no hay aislamiento de datos personales por instalar otra
variante. El catálogo está aislado en memoria, pero guardar una bola usa el
almacenamiento y respaldo normales. No usar la cuenta habitual para crear datos
de prueba ni desinstalar la app habitual para resolver un conflicto de firma.

Desde la raíz del repositorio:

```powershell
dart run tool/catalog/validate_review_catalog.dart
dart run tool/catalog/prepare_local_review.dart
flutter run --debug -t .dart_tool/catalog_review/main.dart
```

No se ha ejecutado aquí la app contra un dispositivo ni una cuenta real.
Después de `flutter clean` o de modificar el JSON, volver a generar el punto de
entrada. Un proceso ya iniciado conserva el snapshot embebido hasta reiniciarlo.

Recorrido manual recomendado:

1. Abrir «Mis bolas → Añadir bola → Buscar en catálogo» y comprobar el aviso
   de revisión. Buscar por nombre y combinar fabricante/estado; probar una
   búsqueda sin resultados y la alternativa manual.
2. Revisar !Q Tour Edition en 15 y 16 lb; verificar que cambia el diferencial.
   Abrir Hyper Venom y comprobar que solo aparece 15 lb. Abrir Phaze II en 12 lb
   y comprobar que no se atribuye Velocity al núcleo desconocido de ese peso.
3. Revisar las seis fichas MOTIV y sus fuentes. Phaze V debe mostrar acabado
   «No disponible» y el formulario debe dejarlo vacío.
4. Cancelar la incorporación y comprobar que no aparece una unidad nueva.
   Con cuenta ficticia, guardar dos unidades del mismo modelo, comprobar sus
   IDs personales distintos y revisar el historial previo.
5. No eliminar datos reales para probar recuperación o resolver errores.

Para salir, detener la ejecución y arrancar explícitamente la entrada normal:

```powershell
flutter run --debug -t lib/main.dart
```

No basta con hot reload para cambiar de punto de entrada. No hay una caché del
catálogo piloto que limpiar. Las bolas personales guardadas de forma explícita
sí permanecen; salir de revisión no las borra ni revierte el respaldo.

## Pruebas y protección del arsenal

**100 pruebas de catálogo superadas, 0 fallos**, incluyendo 34 comprobaciones
nuevas de C3 (33 en el archivo C3 y una ampliación de flujo de arsenal).
Se ejecutan también los casos previos C1/C2, búsqueda, filtros, demo, caché,
entrada manual y errores de actualización.

La prueba del modelo real utiliza Hive en una carpeta temporal, una cuenta
ficticia y `MemoryArsenalStore`; nunca inicializa Firebase. Crea dos unidades
personales de Phaze V y verifica:

- IDs personales distintos entre sí y del ID comercial.
- JSON de la bola previa y de la sesión previa sin modificaciones; misma clave
  de sesión y referencias `ballId` en sus partidas.
- Identificador del mantenimiento previo conservado.
- Dos partidas previas, promedio **175** y mejor partida **200**, recuperadas
  desde Hive tras un fallo de red simulado en la lectura de sesiones.
- Payload de respaldo simulado con las mismas claves de fase A; sin introducir
  `catalogId` y con acabado nulo conservado.

No se cambian `DataRepository`, servicios de respaldo, adaptadores, reglas,
modelos personales ni cálculo de estadísticas. Las nuevas pruebas son locales;
no certifican un respaldo real en un dispositivo o contra Firebase de producción.

Comando reproducible:

```powershell
flutter test --no-pub test/catalog_ball_test.dart test/ball_catalog_repository_test.dart test/catalog_flow_test.dart test/catalog_c1_contract_test.dart test/catalog_c2_review_test.dart test/catalog_c3_local_test.dart
```

El análisis estático de los archivos C3 y la entrada generada termina sin
incidencias. El formateador aislado mantiene el aviso preexistente de include
`flutter_lints` no resuelto; no se instalaron dependencias para corregirlo.

Se compiló correctamente **solo un bundle de depuración**, sin APK ni ejecución
contra Firebase:

```powershell
flutter build bundle --debug --no-pub --target .dart_tool/catalog_review/main.dart --asset-dir build/catalog_c3_preview/flutter_assets
```

Durante las pruebas se ajustaron los selectores al widget desplegable y al
nombre real del campo «Acabado (finish)», y se aisló el cambio de cuenta del
reloj simulado del test. La ejecución final completa pasa. La lectura de sesiones
vacías del doble original de Firestore no se interpretó como pérdida de datos:
el caso nuevo simula un error de red para ejercer el fallback local existente.

## Condiciones antes de activar el catálogo real

1. Aprobar los 28 registros y la política de campos desconocidos; mantener fuera
   IDOL y BVP Sidewinder hasta resolver sus acabados. Revalidar pesos/fuentes si
   se corrige o actualiza cualquier dato; no reemplazar IDs publicados.
2. Resolver las condiciones de redistribución de hechos/selección de datos con
   los titulares de Storm/Roto Grip, Hammer/Brunswick y MOTIV. No hay API/feed
   autorizado ni licencia abierta verificados. El acceso público y la atribución
   no acreditan por sí solos una autorización de base de datos o fotografías.
3. Acordar cómo se presentarán las fuentes indexadas de MOTIV o sustituirlas
   por confirmación/documentación directa. No anunciar disponibilidad en vivo
   a partir de un índice o de «sin existencias».
4. Mantener fotografías ausentes hasta tener permiso documentado para la forma
   de exhibición, redistribución y caché elegidas. No se descargó ninguna.
5. Completar la revisión manual en un entorno de pruebas y, después de otra
   autorización, definir alojamiento, versiones, actualizaciones y reversión.
   No cambiar el seed ni configurar una fuente remota como efecto de estas pruebas.
6. Si se desea vínculo persistente al ID comercial o imágenes en el arsenal,
   tratarlo como trabajo separado de compatibilidad. C3 no amplía el payload
   personal de fase A ni sus reglas.

No se realiza despliegue, publicación, commit ni push. Bolómetro Vision no se toca.

