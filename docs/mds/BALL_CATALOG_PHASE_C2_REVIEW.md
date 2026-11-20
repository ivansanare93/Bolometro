# Fase C2 — catálogo real de revisión, sin activar

Revisión documental: **28-10-2026**. Selección: los 30 IDs de C1, aprobados
provisionalmente por el usuario. La aprobación de la selección no se interpreta
como validación de cada dato ni como autorización de distribución de fotografías.

## Entrega y estado

- **3 listos técnicamente para importar**: !Q Tour Edition, Pitch Black y Phaze III.
- **25 importables con campos desconocidos**, explícitamente nulos o estado desconocido.
- **2 bloqueados y excluidos del snapshot**: IDOL y BVP Sidewinder.
- **28 registros reales**, 134 filas de peso con RG y diferencial, 75 con
  diferencial intermedio publicado, 59 con intermedio desconocido. **0 fotografías**.

«Listo» significa que, para los pesos incluidos y comprobados, hay año, estado,
cubierta, acabado, nombre/tipo de núcleo, RG y diferencial contrastados. No
requiere inventar un diferencial intermedio ausente. No significa autorización
jurídica de publicación ni garantía de que el fabricante siga vendiendo todos
los pesos. «Con desconocidos» indica al menos una de esas carencias; las
carencias no se rellenan a partir de modelos parecidos. Los 28 pueden analizarse
con el parser v1; la distribución general permanece pendiente de revisión.

Archivos:

- `docs/catalog/c2/catalog_real_v2.review.json`: snapshot real, esquema v1,
  versión de contenido 2, separado de los assets y del demo ficticio.
- `docs/catalog/c2/catalog_c2_review.json`: clasificación de los 30, pesos,
  incidencias, modalidad de acceso a las fuentes y puertas de aprobación cerradas.
- `tool/catalog/validate_review_catalog.dart`: validador editorial local.
- `test/catalog_c2_review_test.dart`: pruebas del snapshot y casos negativos.

**No se ha activado el catálogo.** El seed activo continúa vacío y en versión 1;
el demo mantiene `isTestData: true`. No se cambia `pubspec.yaml`, ningún cargador,
URL remota ni caché en ejecución. La versión 2 es un borrador local; antes de
activarlo habrá que revisar su número frente a cualquier versión distribuida.

## Revisión de los 30 candidatos

Los enlaces de cada fila son fuentes oficiales y también están conservados en
el JSON o en el expediente del modelo bloqueado. `checkedAt` representa la
verificación editorial de Bolómetro, no una fecha prometida por el fabricante.
Los pesos muestran cobertura verificada, no un censo de toda variante histórica.

| Modelo y fuente oficial | ID comercial estable | Clasificación | Pesos con RG/DIFF (lb) | Incidencias o alcance |
| --- | --- | --- | --- | --- |
| [Beyond Infinity](https://brunswickbowling.com/products/balls/retired/beyond-infinity) | `brunswick.beyond-infinity` | Con desconocidos | 12, 13, 14, 15, 16 | RETIRED en ficha; fecha de retirada desconocida. |
| [BVP Sidewinder](https://brunswickbowling.com/uploads/downloads/Ball-Info-Sheets/Archive/BVP-Sidewinder-Info-Sheet.pdf) | `brunswick.bvp-sidewinder` | Bloqueado | — | El mismo PDF indica Rough Buff en Factory Finish y High Gloss Polish en Out of the Box; sin segunda fuente que resuelva la discrepancia. Solo hay cifras explícitas a 16 lb. |
| [Combat Solid](https://brunswickbowling.com/products/balls/current/combat-solid) | `brunswick.combat-solid` | Con desconocidos | 12, 13, 14, 15, 16 | Nombre Rampart documentado para 14–16 lb; no se asigna a núcleo ligero. |
| [Endeavor](https://brunswickbowling.com/products/balls/retired/endeavor) | `brunswick.endeavor` | Con desconocidos | 12, 13, 14, 15, 16 | Intermedio no publicado, permanece null. Retirada 2024-11-25. |
| [Infinity Quest Pearl](https://brunswickbowling.com/products/balls/current/infinity-quest-pearl?slide=0) | `brunswick.infinity-quest-pearl` | Con desconocidos | 12, 13, 14, 15, 16 | No se confunde con Beyond Infinity aunque compartan cifras de núcleo. |
| [Ultimate Defender](https://brunswickbowling.com/products/balls/retired/ultimate-defender) | `brunswick.ultimate-defender` | Con desconocidos | 12, 13, 14, 15, 16 | Retirada explícita 2024-11-25. |
| [Arctic Vibe](https://hammerbowling.com/products/arctic-vibe) | `hammer.arctic-vibe` | Con desconocidos | 10, 11, 12, 13, 14, 15, 16 | Se conservan las siete filas 10–16 lb. No se atribuye Vibe a 10–13 lb sin prueba. |
| [Black Widow 3.0](https://hammerbowling.com/products/black-widow-3-0) | `hammer.black-widow-3-0` | Con desconocidos | 12, 13, 14, 15, 16 | Nombre del núcleo documentado para 14–16 lb. Tipo y nombre del núcleo ligero sin afirmar. |
| [Full Effect](https://hammerbowling.com/products/full-effect) | `hammer.full-effect` | Con desconocidos | 12, 13, 14, 15, 16 | Tipo de cubierta según BALL SPECS; no se usa pearl de la descripción comercial. Filas verificadas individualmente aunque coincidan con Effect. |
| [Hammer Effect](https://hammerbowling.com/products/hammer-effect) | `hammer.hammer-effect` | Con desconocidos | 12, 13, 14, 15, 16 | Retirada explícita: 2025-12-02. Núcleo ligero sin identificar; simetría no inferida de ASY. |
| [Maximum Effect](https://hammerbowling.com/products/maximum-effect) | `hammer.maximum-effect` | Con desconocidos | 12, 13, 14, 15, 16 | Sin evidencia suficiente para declarar current/discontinued. No se usa una reseña como estado. |
| [True Blood](https://hammerbowling.com/products/true-blood) | `hammer.true-blood` | Con desconocidos | 12, 13, 14, 15, 16 | Año, estado, simetría e intermedio no verificados. Se conserva literalmente la secuencia 800-800 publicada. |
| [Black Venom](https://www.motivbowling.com/products/balls/light-medium-oil/black-venom.html) | `motiv.black-venom` | Con desconocidos | 12, 13, 14, 15, 16 | La tabla HTML cotejada ofrece 2.47 para 15 lb; no se usa ni corrige el .247 indexado del PDF. Año 2023 pendiente de documento legible directo; se deja null. Estado sin confirmar. |
| [Covert Revolt](https://www.motivbowling.com/products/balls/retired-balls/covert-revolt.html) | `motiv.covert-revolt` | Con desconocidos | 12, 13, 14, 15, 16 | Declaración oficial de retirada; tipo solid explícito en High Friction Solid. No se completa simetría ni año por intuición. |
| [Hyper Venom](https://www.motivbowling.com/userfiles/filemanager/dxx22yeosycufrut6yih) | `motiv.hyper-venom` | Con desconocidos | 15 | Solo se verifican las cifras explícitas de 15 lb del sell sheet indexado. No se interpreta el índice como confirmación de otros pesos ni año ni simetría. |
| [Venom Recoil](https://www.motivbowling.com/products/balls/retired-balls/venom-recoil.html?page=1) | `motiv.venom-recoil` | Con desconocidos | 12, 13, 14, 15, 16 | Retirada 2021-10-28 según ficha indexada. No se deduce año de lanzamiento ni tipo solid/pearl/hybrid de MFS. |
| [Venom Shock](https://www.motivbowling.com/shop/venom-shock.html) | `motiv.venom-shock` | Con desconocidos | 12, 13, 14, 15, 16 | Datos de tabla del resultado oficial indexado. Ignorado párrafo que nombra Hyper Venom. Disponibilidad pendiente; la fecha de consulta no acredita actualización del fabricante. |
| [Venom Shock Pearl](https://www.motivbowling.com/products/balls/retired-balls/venom-shock-pearl.html) | `motiv.venom-shock-pearl` | Con desconocidos | 12, 13, 14, 15, 16 | La tabla técnica indica .035 en 15 lb; reseña .034 excluida. Tipo de núcleo, lanzamiento e intermedio desconocidos. Estado basado en archivo individual. |
| [Attention Star](https://www.stormbowling.com/roto-grip-attention-star-bowling-ball) | `roto-grip.attention-star` | Con desconocidos | 12, 13, 14, 15, 16 | Año y métricas completados desde ficha y tech sheet actualizado. Disponibilidad actual no confirmada independientemente del atributo de pedidos. |
| [IDOL](https://www.stormbowling.com/products/featured/bowling-balls-archive/bbmrid-idol) | `roto-grip.idol` | Bloqueado | — | Acabado 2000-Grit Polished sin contraste oficial independiente suficiente; no se sustituye por Abralon por analogía con IDOL Helios. |
| [Magic Gem](https://www.stormbowling.com/roto-grip-magic-gem-bowling-ball) | `roto-grip.magic-gem` | Con desconocidos | 12, 13, 14, 15, 16 | DIFF y acabado confirmados en PDF; estado comercial y núcleo ligero desconocidos. |
| [Perfect Gem](https://www.stormbowling.com/roto-grip-perfect-gem-bowling-ball) | `roto-grip.perfect-gem` | Con desconocidos | 12, 13, 14, 15, 16 | E-R1 confirmado en tech sheet; no inferido del código R_ER1. Núcleo 12–13 lb desconocido. |
| [RST Hyperdrive Pearl](https://www.stormbowling.com/roto-grip-rst-hyperdrive-pearl-bowling-ball) | `roto-grip.rst-hyperdrive-pearl` | Con desconocidos | 12, 13, 14, 15, 16 | Núcleo 12–13 lb sin identificar. |
| [Transformer](https://www.stormbowling.com/roto-grip-transformer-bowling-ball) | `roto-grip.transformer` | Con desconocidos | 12, 13, 14, 15, 16 | Cifras comerciales anteriores al taladrado. Núcleo 12–13 lb sin identificar. |
| [Hy-Road](https://www.stormbowling.com/storm-hy-road-bowling-ball) | `storm.hy-road` | Con desconocidos | 12, 13, 14, 15, 16 | Acabado de ficha y PDF actuales: Power Edge. No describe todas las unidades fabricadas desde 2008. Núcleo sin verificar para 12–13 lb; no se hereda Inverted Fe2. |
| [!Q Tour Edition](https://www.stormbowling.com/storm-iq-tour-edition-bowling-ball) | `storm.iq-tour-edition` | Listo | 12, 13, 14, 15, 16 | El tech sheet identifica C3 para 12–16 lb. No se copian cifras de variantes Emerald/Pearl. |
| [Phaze II](https://www.stormbowling.com/storm-phaze-ii-bowling-ball) | `storm.phaze-ii` | Con desconocidos | 12, 13, 14, 15, 16 | Núcleo 12–13 lb sin nombre/tipo verificado; sin fallback global. |
| [Phaze III](https://www.stormbowling.com/products/featured/bowling-balls-archive/bbmtzf-phaze-iii) | `storm.phaze-iii` | Listo | 14, 15, 16 | Cobertura limitada a los tres pesos 14–16 lb enumerados por esta ficha; no se afirma inexistencia de otras variantes. |
| [Phaze V](https://www.stormbowling.com/storm-phaze-V-bowling-ball) | `storm.phaze-v` | Con desconocidos | 14, 15, 16 | El PDF indexado menciona Reacta Gloss, pero su URL devolvió 404; acabado null hasta confirmar un recurso accesible. Solo tres pesos verificados; Out of Stock no acredita retirada. |
| [Pitch Black](https://www.stormbowling.com/storm-pitch-black-bowling-ball) | `storm.pitch-black` | Listo | 12, 13, 14, 15, 16 | Tech sheet identifica Capacitor para 12–16 lb; simetría cotejada con ficha. |

## Cobertura por peso y fabricante

| Fabricante | En JSON | Bloqueados | Filas de peso con RG/DIFF |
| --- | ---: | ---: | ---: |
| Storm | 6 | 0 | 26 |
| Roto Grip | 5 | 1 | 25 |
| Hammer | 6 | 0 | 32 |
| Brunswick | 5 | 1 | 25 |
| MOTIV | 6 | 0 | 26 |
| **Total** | **28** | **2** | **134** |

- 24 modelos: filas verificadas de 12, 13, 14, 15 y 16 lb.
- Arctic Vibe: siete filas de 10 a 16 lb.
- Phaze III y Phaze V: únicamente 14, 15 y 16 lb según las fichas contrastadas.
- Hyper Venom: únicamente 15 lb explícitas del sell sheet indexado. No se
  completan los demás pesos con las cifras de Gear o Venom Shock.

Las 134 filas tienen RG y diferencial numéricos. Los datos de cada fila fueron
consultados, aunque existan coincidencias entre modelos. Por ejemplo, !Q Tour
Edition tiene .029 a 15 lb y .035 a 16 lb; Hy-Road tiene RG 2.57 a 15 lb y 2.52
a 16 lb. No se trasladan las cifras predeterminadas de 16 lb de la tienda a 15 lb.

El nombre/tipo del núcleo puede ser desconocido para ciertos pesos incluso
cuando se conocen RG y diferencial. En Storm Phaze II/Hy-Road, los cinco Roto
Grip, los seis Hammer y los cinco Brunswick se evita el fallback a un núcleo
principal no confirmado en pesos bajos: campos globales nulos y nombre por peso
solo donde está documentado. Tampoco se deduce simetría de que exista ASY.
Los nulos están conservados y probados; no son ceros ni valores calculados.

## Discrepancias resueltas o retenidas

1. **Hy-Road**: la [ficha actual](https://www.stormbowling.com/storm-hy-road-bowling-ball)
   y el [tech sheet enlazado](https://stormproducts.nyc3.cdn.digitaloceanspaces.com/product_pages/Balls/Storm/Hy-Road/TS_hyroad.pdf)
   coinciden en **Power Edge**. Se registra como especificación comercial actual;
   no se aplica a unidades antiguas ni se modifica el acabado de ninguna bola
   personal. El Reacta Gloss recogido en C1 queda superado para este borrador.
2. **Perfect Gem, RST Hyperdrive Pearl, Transformer, Attention Star y Magic Gem**:
   se consultaron los tech sheets oficiales enlazados por sus fichas. Se completan
   tablas 12–16 lb e intermedios. Las URL de esos PDFs quedan en `sources` y las
   métricas apuntan al documento correspondiente mediante `fieldSources`.
   Magic Gem confirma 2000-grit Abralon y DIFF .053 a 15 lb. Attention Star
   confirma año 2024 y acabado Reacta Gloss, sin asumir estado actual por su SKU.
3. **Black Venom**: la [tabla HTML oficial](https://www.motivbowling.com/products/balls/light-medium-oil/black-venom.html)
   confirma RG **2.47** a 15 lb, DIFF .036 e intermedio .013. No se corrige por
   intuición el .247 del índice del PDF: se usa otra evidencia oficial explícita.
   El año se deja nulo porque el PDF de lanzamiento no devolvió texto extraíble
   en acceso directo; no se usa su antigüedad indexada como año.
4. **Venom Shock Pearl**: la tabla oficial confirma DIFF **.035 a 15 lb**.
   Se excluye la cifra .034 de una reseña incluida en la misma página.
5. **Venom Shock**: se usan tabla y cabecera del resultado oficial indexado,
   no el párrafo que nombra Hyper Venom. El acabado es 4000 Grit LSS según esa
   ficha. Disponibilidad desconocida; acceso directo recibió HTTP 429.
6. **Full Effect**: `BALL SPECS` identifica **Hybrid Reactive**. El texto
   comercial lo denomina también pearl/shiny pearl; se prioriza el campo técnico
   estructurado y se registra esta diferencia, sin clasificar la cubierta por
   adjetivos comerciales. Si el fabricante rectifica la ficha, requerirá revisión.
7. **Phaze V**: el PDF encontrado en C1 menciona Reacta Gloss en el índice,
   pero su URL oficial devuelve 404. La ficha HTML no tiene acabado explícito.
   Por ello `factoryFinish: null`; sí se mantienen las tres filas verificadas.
8. **IDOL, bloqueado**: la ficha de archivo mantiene «2000-Grit Polished».
   No se encontró contraste oficial suficiente para aceptar o corregir ese
   acabado. IDOL Helios es otro modelo y no resuelve la duda. Queda fuera de
   este primer snapshot por criterio editorial conservador.
9. **BVP Sidewinder, bloqueado**: el mismo [PDF oficial](https://brunswickbowling.com/uploads/downloads/Ball-Info-Sheets/Archive/BVP-Sidewinder-Info-Sheet.pdf)
   indica Rough Buff en cabecera y High Gloss Polish en el texto de fábrica.
   No se ha resuelto. Las cifras explícitas son de 16 lb; no se genera una tabla
   10–16 lb a partir de ellas. Se conserva el expediente sin importar la bola.

En los puntos 7–9 se intentó contrastar fuentes oficiales sin sustituirlas por
reseñas, tiendas o suposiciones. No se afirma que todas las discrepancias hayan
quedado resueltas. Se excluyen textos comerciales, imágenes y PDFs completos del
archivo distribuible: solo datos puntuales y referencias editoriales.

## Procedencia, permisos y disponibilidad

Cada campo no nulo dispone de procedencia. Las claves de métricas usan el peso
nominal, por ejemplo `weights.15.rgInches`, no la posición en el array. El año
y el estado tienen su fuente cuando se conocen. Las fotografías son siempre
`null`, sin URLs de imagen, permisos ficticios ni descargas de recursos gráficos.

MOTIV Black Venom y Venom Shock Pearl se contrastaron con páginas oficiales
accesibles mediante la herramienta. Venom Shock, Venom Recoil y Covert Revolt
se verificaron mediante resultados indexados oficiales tras respuestas HTTP
429 en acceso directo; Hyper Venom mediante el texto indexado de su PDF oficial,
cuya apertura no devolvió texto extraíble. Estas modalidades están identificadas
en el expediente y **no equivalen a verificación en vivo de disponibilidad**.
No se eludieron bloqueos ni se programó scraping.

El estado actual se apoya en colecciones/oferta oficial y fichas, no en reseñas
ni en la mera ausencia de una retirada. Hammer Black Widow 3.0, Arctic Vibe y
Full Effect aparecen en la [colección oficial](https://hammerbowling.com/collections/balls).
Maximum Effect y True Blood mantienen estado desconocido. Las retiradas de
Hammer Effect, Ultimate Defender, Endeavor y Venom Recoil tienen fechas explícitas;
las otras retiradas se apoyan en archivos individuales/etiquetas oficiales.

**Pendientes de alcance general antes de activar:** no se ha verificado una
licencia abierta ni un acuerdo de redistribución de la selección de datos de los
fabricantes. Las condiciones para fotos, bases de datos y feeds no se dan por
aprobadas por el acceso público a las fichas. Los 3 «listos» son una clasificación
técnica: no hay un permiso jurídico confirmado automáticamente para ellos.
No se contactó con fabricantes ni se contrató un servicio. Una fase posterior
deberá resolver condiciones aplicables y las autorizaciones necesarias para la
forma de distribución elegida. Las imágenes requieren autorización documentada
independiente; mientras tanto seguirá la alternativa visual existente.

## Compatibilidad y protección del arsenal

No se modifica el parser v1 de la app, modelos personales, adaptadores Hive,
IDs, sesiones, estadísticas, mantenimientos, sincronización ni reglas Firebase.
El validador editorial es una herramienta de revisión independiente; añade
comprobaciones más estrictas sin invalidar cachés antiguas en la aplicación.

Los IDs comerciales de C1 se conservan. Los dos excluidos no se asignan a otro
modelo. Se permiten varias unidades personales mediante el flujo existente:
la selección comercial precarga el formulario y guardar genera su propio ID.
«Añadir manualmente» no cambia y está cubierta por las pruebas existentes.

## Validación reproducible y siguiente decisión

Desde la raíz del repositorio, con dependencias existentes:

```powershell
dart run tool/catalog/validate_review_catalog.dart
flutter test --no-pub test/catalog_ball_test.dart test/ball_catalog_repository_test.dart test/catalog_flow_test.dart test/catalog_c1_contract_test.dart test/catalog_c2_review_test.dart
flutter analyze --no-pub tool/catalog/validate_review_catalog.dart test/catalog_c2_review_test.dart
```

El validador solo lee archivos y muestra un resumen; no importa datos al arsenal,
no actualiza Hive, no usa Firebase y no activa el catálogo. Comprueba identidad,
procedencia por campo, fuentes oficiales del piloto, pesos, límites numéricos
amplios para detectar errores de transcripción (no certificación USBC), fechas,
separación de demo, recuentos y exclusión de modelos bloqueados. Las pruebas
inyectan duplicados, pesos fraccionarios/no revisados, medidas inválidas, campos
obligatorios ausentes, fuentes falsas y cambios de las puertas de aprobación.
No convierten las afirmaciones comerciales ni los permisos en hechos demostrados
por software: la verificación editorial de fuentes sigue siendo necesaria.

Resultados finales:

- **66 pruebas superadas, 0 fallos**: las 40 anteriores de catálogo más 26 de C2.
- **Análisis estático sin incidencias** en los dos archivos Dart nuevos.
- Comando independiente del validador: **válido, 28 modelos, 134 filas,
  activated=false**.
- `git diff --check` sin incidencias; seed comercial activo vacío.

Durante el desarrollo se corrigió una importación relativa del modelo que Dart
trataba como tipo distinto al import de paquete; la ejecución final usa el mismo
import de paquete en herramienta y tests y pasa completa. El formateador aislado
avisa de un include `flutter_lints` no resuelto en la configuración existente;
el análisis posterior con Flutter termina sin incidencias. No se instalaron
dependencias para estas comprobaciones. No se ejecutaron pruebas de red o de
producción, ni se necesitó una cuenta Firebase.

**Decisión solicitada después de la revisión:** aprobar o ajustar los 28 registros
propuestos y su política de campos desconocidos; resolver las condiciones de
redistribución antes de habilitarlos. Este trabajo no cambia el catálogo activo
ni autoriza un despliegue. No se realiza commit, push ni publicación.

