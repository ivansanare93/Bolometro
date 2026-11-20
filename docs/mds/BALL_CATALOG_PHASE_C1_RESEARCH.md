# Fase C1: fuentes y selección del piloto — pendiente de aprobación

Consulta: **28 de octubre de 2026**. Alcance: investigación documental y pruebas
locales del contrato existente. **Ninguno de estos 30 candidatos se incorpora
al JSON distribuido por la app. No hay fotografías autorizadas.**

## Resultado y límites de la verificación

Hay fuentes oficiales suficientes para proponer un piloto de **30 modelos,
seis por fabricante**, con modelos recientes y de archivo. No todos están
listos para publicación: algunas fichas requieren contrastar pesos, acabados,
estado comercial o fecha de lanzamiento. Las tablas siguientes separan esos
casos. Un enlace oficial y una especificación comprobada no acreditan una
licencia de redistribución de la base de datos o de sus fotografías.

La revisión se hizo consultando páginas concretas y resultados indexados del
fabricante, sin desarrollar recolectores ni acceder a endpoints internos.
Parte de la evidencia procede de copias indexadas: su fecha de rastreo no es
la fecha de actualización del producto. MOTIV devolvió HTTP 429 en el acceso
directo a su portada; no se intentó eludirlo. Sus resultados oficiales y PDFs
permiten una preselección documental, pero requieren una revisión directa
posterior antes de publicar. No se usan reseñas de compradores como ficha
técnica, aunque aparezcan dentro del sitio oficial.

## Fuentes, estructura y condiciones

| Marca | Fuentes oficiales consultadas | Información utilizable para revisión | Permisos y limitaciones pendientes |
| --- | --- | --- | --- |
| Storm | [Catálogo](https://www.stormbowling.com/products/equipment/bowling-balls/), fichas y PDFs enlazados; [archivo Phaze III](https://www.stormbowling.com/products/featured/bowling-balls-archive/bbmtzf-phaze-iii) | HTML con SKU, cubierta, núcleo, acabado, fecha y métricas; fichas históricas con filas por peso | No se localizó una API pública documentada ni una licencia abierta de extracción/redistribución. Los códigos internos del comercio no son un esquema estable. |
| Roto Grip | [Portal oficial dentro de Storm](https://www.stormbowling.com/roto-grip-brand), fichas; [archivo IDOL](https://www.stormbowling.com/products/featured/bowling-balls-archive/bbmrid-idol) | Comparte infraestructura; fichas y documentación técnica | Mismas reservas; verificar derechos de cada marca y variante, no asumir que un permiso Storm cubra Roto Grip. |
| Hammer | [Bolas](https://hammerbowling.com/collections/balls), [retiradas](https://hammerbowling.com/collections/retired-balls), fichas y documentos enlazados | Tablas HTML RG/DIFF/ASY por peso. Algunas páginas contienen JSON de variantes de tienda | Ese JSON no es una API autorizada del catálogo: puede mostrar variantes genéricas, disponibilidad y precio ficticios para fichas históricas. No hay licencia abierta verificada. |
| Brunswick | [Actuales](https://brunswickbowling.com/products/balls/current), [retiradas](https://brunswickbowling.com/products/balls/retired), fichas y PDFs de archivo | Tablas HTML por peso, SKU, lanzamiento y en ciertos casos fecha de retirada | No se verificó API/feed público con condiciones de reutilización. Los términos de servicios técnicos/Sync no equivalen a licencia del catálogo de bolas. |
| MOTIV | [Archivo](https://www.motivbowling.com/products/balls/retired-balls/), fichas individuales y sell sheets oficiales | Tablas por peso, cubierta, acabado, núcleo y algunas fechas de retirada | Acceso directo limitado; varias evidencias son indexadas. No hay API/licencia de redistribución verificada. El menú mezcla familias actuales y antiguas: no prueba por sí solo que un producto esté retirado. |

**Corrección importante:** [Memory Lane](https://www.stormbowling.com/memory-lane)
describe una visita al museo físico de Storm; no debe emplearse como archivo
técnico de bolas descatalogadas. El [catálogo oficial 2022–2023](https://www.stormbowling.com/medias/StormCatalog_allbrands_2022_88_small.pdf)
sirve como fuente histórica, no para inferir disponibilidad en 2026.

No se encontró en las fuentes revisadas un conjunto de datos con licencia
abierta que sustituya estas verificaciones. Esto no prueba que no exista ni
que los fabricantes no ofrezcan acuerdos privados. Costes, cuotas, acceso y
actualizaciones de un eventual feed están **sin confirmar**, no se consideran
gratuitos por defecto.

La [política de privacidad de Hammer](https://hammerbowling.com/pages/privacy-policy)
identifica empresas y tratamiento de datos; no concede permiso sobre fotos ni
bases de datos. Los botones «Download», «Ball Image» y «Sell Sheet» permiten
localizar recursos, pero no acreditan autorización para incluirlos en una app,
redistribuirlos, enlazarlos como imágenes remotas o almacenarlos en caché.

**Criterio propuesto:** preparar manualmente hechos técnicos con referencias,
sin copiar textos comerciales ni PDFs completos; antes de distribuir el piloto,
cerrar la revisión de condiciones aplicables y, donde no sean claras, obtener
confirmación escrita del titular. Para fotografías, mantener `photo: null`
hasta verificar autorización expresa de exhibición, redistribución y caché.
La atribución por sí sola no sustituye al permiso. No se han enviado solicitudes
a fabricantes ni se ha asumido una interpretación jurídica definitiva.

## Selección propuesta: 30 candidatos

Todos los enlaces de esta sección se revisaron documentalmente el
**2026-10-28**. Los IDs son propuestas estables de Bolómetro, independientes
del URL y del ID personal; aún no se reservan en un catálogo publicado.
`Actual*` significa presente en el catálogo/oferta oficial revisada y con fecha
de lanzamiento ya transcurrida, sujeto a reconfirmación al publicar.
`Desconocido` evita deducir una retirada a partir de «sin existencias».

### Storm

| ID propuesto / ficha oficial | Estado propuesto | Evidencia técnica comprobada y pendiente |
| --- | --- | --- |
| [`storm.phaze-ii`](https://www.stormbowling.com/storm-phaze-ii-bowling-ball) | Actual* | TX-16 Solid, Velocity; listado: 3000 grit, 16 lb RG 2.48 / DIFF .051. Lanzamiento 2016. Completar auditoría de tech sheet por peso. |
| [`storm.iq-tour-edition`](https://www.stormbowling.com/storm-iq-tour-edition-bowling-ball) | Actual* | R2S Solid, C3C, 4000 grit; listado: 16 lb 2.49 / .035. Lanzamiento 2012. Faltan otras filas verificadas por peso. |
| [`storm.pitch-black`](https://www.stormbowling.com/storm-pitch-black-bowling-ball) | Actual* | Controll Urethane, Capacitor, 1000 grit; 16 lb 2.56 / .023. Lanzamiento 2014. Revisar tech data para restantes pesos. |
| [`storm.hy-road`](https://www.stormbowling.com/storm-hy-road-bowling-ball) | Actual* | R2S Hybrid, Inverted Fe2; listado actual Reacta Gloss, 16 lb 2.52 / .058; lanzamiento 2008. Contrastar acabado y posibles versiones históricas antes de fijarlo. |
| [`storm.phaze-iii`](https://www.stormbowling.com/products/featured/bowling-balls-archive/bbmtzf-phaze-iii) | Descatalogada: archivo oficial | R3S Hybrid Reactive, Velocity simétrico, 1500-grit polished. Año 2019; tabla 14–16 lb: 14=2.53/.050, 15=2.48/.051, 16=2.48/.051. No extrapolar a pesos menores. |
| [`storm.phaze-v`](https://www.stormbowling.com/storm-phaze-V-bowling-ball) | Desconocido | R2S Pearl Reactive, Velocity simétrico, lanzamiento 2022; tabla 14–16 lb igual a la anterior en esos pesos. El resultado «Out of Stock» no demuestra retirada; acabado pendiente. |

### Roto Grip

| ID propuesto / ficha oficial | Estado propuesto | Evidencia técnica comprobada y pendiente |
| --- | --- | --- |
| [`roto-grip.perfect-gem`](https://www.stormbowling.com/roto-grip-perfect-gem-bowling-ball) | Actual* | Gem + A.I., E-R1 Solid Reactive, 2000 grit; 16 lb RG 2.49 / DIFF .055 / PSA .017; lanzamiento 02-10-2026. Verificar tech data de otros pesos y nomenclatura de cubierta. |
| [`roto-grip.rst-hyperdrive-pearl`](https://www.stormbowling.com/roto-grip-rst-hyperdrive-pearl-bowling-ball) | Actual* | RST + A.I., U-R1 Pearl Reactive, Power Edge; listado 16 lb 2.51/.051/PSA .016; lanzamiento 2025. Otras filas pendientes. |
| [`roto-grip.transformer`](https://www.stormbowling.com/roto-grip-transformer-bowling-ball) | Actual* | Morph-Wing asimétrico, V-R1 Solid Reactive, 4000 grit; listado 16 lb 2.50/.050/PSA .015; lanzamiento 2026. No confundir cifras sin taladrar con cifras posteriores al taladrado. |
| [`roto-grip.attention-star`](https://www.stormbowling.com/roto-grip-attention-star-bowling-ball) | Desconocido | Identidad oficial BBMRZS; Momentous + A.I., eTrax PLUS Pearl. Pendientes tabla por peso, acabado, año documentado y estado comercial antes de importación. |
| [`roto-grip.magic-gem`](https://www.stormbowling.com/roto-grip-magic-gem-bowling-ball) | Desconocido | BBMRIG, Defiant LRG asimétrico, MicroTrax Hybrid; 15 lb RG 2.47 / PSA .016; lanzamiento 2023. DIFF, acabado y otros pesos pendientes de contraste. |
| [`roto-grip.idol`](https://www.stormbowling.com/products/featured/bowling-balls-archive/bbmrid-idol) | Descatalogada: archivo oficial | Ikon simétrico, MicroTrax-S18 Solid Reactive; 2018. 14=2.54/.049, 15=2.49/.052, 16=2.49/.049. La ficha dice «2000-Grit Polished»: acabado bloqueado hasta contrastarlo con documentación técnica. |

### Hammer

| ID propuesto / ficha oficial | Estado propuesto | Evidencia técnica comprobada y pendiente |
| --- | --- | --- |
| [`hammer.black-widow-3-0`](https://hammerbowling.com/products/black-widow-3-0) | Desconocido | Gas Mask, HK22–Aggression Solid / Solid Reactive; 500/1000/2000 Siaair, lanzamiento 2024. Tabla 12–16 lb completa; 15 lb 2.500/.058/ASY .016. Reconfirmar presencia en gama actual. |
| [`hammer.arctic-vibe`](https://hammerbowling.com/collections/balls/products/arctic-vibe) | Desconocido | Vibe, HK22–CT Max Hybrid / Hybrid Reactive; 500/1000/1500 Siaair + Factory Compound; 2024. Tabla 10–16 lb; 15 lb 2.510/.042. Estado por confirmar; no asumir mismo núcleo en todos los pesos. |
| [`hammer.hammer-effect`](https://hammerbowling.com/products/hammer-effect) | Descatalogada: retirada 02-12-2025 | Huntsman, HK22–Cohesion Pearl / Pearl Reactive; 500/1000/1500 Siaair + Factory Compound; lanzamiento 2024. Tabla 12–16 lb; 15 lb 2.470/.050/ASY .017. |
| [`hammer.full-effect`](https://hammerbowling.com/products/full-effect) | Desconocido | Huntsman, HK22C² Hybrid / Hybrid Reactive; 500/1000/1500 Siaair + Factory Compound; lanzamiento 19-03-2026. Tabla 12–16 lb; 15 lb 2.470/.050/ASY .017. Verificar estado actual. |
| [`hammer.maximum-effect`](https://hammerbowling.com/products/maximum-effect) | Desconocido | Huntsman, HK22–Cohesion Hybrid CFI / Hybrid Reactive; 500/1500 Siaair; lanzamiento 2025. Tabla 12–16 lb; 15 lb 2.470/.050/ASY .017. Verificar estado actual. |
| [`hammer.true-blood`](https://hammerbowling.com/products/true-blood) | Desconocido | Polyester, First Blood Core, acabado 800-800-1000-2000 + Powerhouse Factory Finish Polish. Tabla 12–16 lb; 15 lb 2.52/.054. Año, retirada, tipo de núcleo e intermedio no confirmados. |

### Brunswick

| ID propuesto / ficha oficial | Estado propuesto | Evidencia técnica comprobada y pendiente |
| --- | --- | --- |
| [`brunswick.combat-solid`](https://brunswickbowling.com/products/balls/current/combat-solid) | Actual* | Rampart, HK22C²–Alpha Premier Solid / Solid Reactive; 500/1500 Siaair; lanzamiento 13-08-2026. Tabla 12–16 lb; 15 lb 2.502/.051/ASY .019. |
| [`brunswick.infinity-quest-pearl`](https://brunswickbowling.com/products/balls/current/infinity-quest-pearl?slide=0) | Actual* | Infinity, HK22C–EVO Pearl / Pearl Reactive; 500/1000/1500 Siaair + Crown Factory Compound; 11-06-2026. Tabla 12–16 lb; 15 lb 2.521/.051/ASY .010. |
| [`brunswick.ultimate-defender`](https://brunswickbowling.com/products/balls/retired/ultimate-defender) | Descatalogada: retirada 25-11-2024 | Portal X, HK22–A.C.T. 3.0 Hybrid / Hybrid Reactive, 500/2000 Siaair; lanzamiento 2024. Tabla 12–16 lb; 15 lb 2.473/.054/ASY .015. |
| [`brunswick.endeavor`](https://brunswickbowling.com/products/balls/retired/endeavor) | Descatalogada: retirada 25-11-2024 | Tiered Hexagon, Activator Plus 3.0 Pearl / Pearl Reactive; 500/1000/1500 Siaair + Crown Factory Compound; lanzamiento 2024. Tabla 12–16 lb; 15 lb 2.540/.045; intermedio no publicado en tabla. |
| [`brunswick.beyond-infinity`](https://brunswickbowling.com/products/balls/retired/beyond-infinity) | Descatalogada: archivo y etiqueta RETIRED | Infinity, HK22–A.X.H. Pearl / Pearl Reactive; 500/1000/1500 Siaair + Crown Factory Compound; lanzamiento 2024. Tabla 12–16 lb; 15 lb 2.521/.051/ASY .010. |
| [`brunswick.bvp-sidewinder`](https://brunswickbowling.com/uploads/downloads/Ball-Info-Sheets/Archive/BVP-Sidewinder-Info-Sheet.pdf) | Desconocido: documento histórico | Rocket, cubierta híbrida solid/pearl con partículas; 16 lb RG mínimo 2.489 / DIFF .045. Se anuncian 10–16 lb, pero falta comprobar tabla por peso. Rough Buff en cabecera y High Gloss Polish en texto: resolver acabado. Año no confirmado. |

### MOTIV

En esta marca la evidencia técnica incluye resultados indexados oficiales.
No se equipara su consulta con una verificación en vivo de disponibilidad.

| ID propuesto / ficha oficial | Estado propuesto | Evidencia técnica comprobada y pendiente |
| --- | --- | --- |
| [`motiv.venom-shock`](https://www.motivbowling.com/shop/venom-shock.html) | Desconocido | Gear simétrico, Turmoil MFS Solid Reactive, 4000 Grit LSS. Tabla 12–16 lb; 15 lb 2.48/.034. Fecha 28-03-2014 en [ficha indexada](https://www.motivbowling.com/products/balls/light-medium-oil/venom-shock.html?page=2). Confirmar vigencia y versiones de acabado. |
| [`motiv.black-venom`](https://www.motivbowling.com/products/balls/light-medium-oil/black-venom.html?hss_channel=tw-33955908) | Desconocido | Gear APG asimétrico, Leverage MFS Solid Reactive, 4000 Grit LSS; tabla 12–16 lb; 15 lb 2.47/.036/intermedio .013. Año 2023 en sell sheet; cotejar ficha directamente antes de publicación. |
| [`motiv.hyper-venom`](https://www.motivbowling.com/userfiles/filemanager/dxx22yeosycufrut6yih) | Desconocido | Sell sheet oficial: Gear, Propulsion MXR Pearl Reactive, 5500 Grit LSP; explícitamente 15 lb 2.48/.034. Resto de pesos, tipo de núcleo y lanzamiento pendientes. PDF indexado; apertura directa sin texto extraíble. |
| [`motiv.venom-recoil`](https://www.motivbowling.com/products/balls/retired-balls/venom-recoil.html?page=1) | Descatalogada: retirada 28-10-2021 | Gear APG asimétrico, Coercion MFS Reactive, 4000 Grit LSS; tabla 12–16 lb; 15 lb 2.47/.036/intermedio .013. Tipo específico de cubierta y lanzamiento por confirmar. |
| [`motiv.venom-shock-pearl`](https://www.motivbowling.com/products/balls/retired-balls/venom-shock-pearl.html) | Descatalogada: ruta de archivo individual | Top Gear, Hexion MFP Pearl Reactive, 5500 Grit LSP; tabla 12–16 lb; 15 lb 2.47/.035. Tipo de núcleo, año e intermedio sin confirmar. |
| [`motiv.covert-revolt`](https://www.motivbowling.com/products/balls/retired-balls/covert-revolt.html) | Descatalogada: declaración explícita | Vanquish, Turmoil HFS, 4000 Grit Laser Scan Sanded; tabla 12–16 lb; 15 lb 2.47/.056. Cubierta solid descrita en texto; tipo de núcleo, lanzamiento e intermedio pendientes. |

## Control técnico antes de convertir candidatos a JSON

Los números anteriores son muestras de verificación, no una transcripción
completa preparada para importación. «Tabla completa» indica que la fuente
presenta filas para ese intervalo; no que exista ya un registro validado para
cada fila. Las pulgadas de RG/DIFF/ASY deben conservarse como tales. Ejemplos
que justifican el almacenamiento por peso:

| Modelo / fuente enlazada arriba | Peso (lb) | RG (in) | DIFF (in) | Intermedio (in) |
| --- | ---: | ---: | ---: | ---: |
| Black Widow 3.0 | 12 | 2.612 | .043 | .011 |
| Black Widow 3.0 | 15 | 2.500 | .058 | .016 |
| Black Widow 3.0 | 16 | 2.510 | .048 | .015 |
| Black Venom | 12 | 2.63 | .020 | .007 |
| Black Venom | 15 | 2.47 | .036 | .013 |
| Black Venom | 16 | 2.48 | .032 | .011 |
| Venom Shock Pearl | 14 | 2.50 | .039 | desconocido |
| Venom Shock Pearl | 15 | 2.47 | .035 | desconocido |

Incidencias que bloquean completar campos automáticamente:

- Storm muestra con frecuencia **Weight: 16**. No asignar esas cifras a 15 lb.
  Etiquetas como `S_Light Weight` no identifican por sí solas el núcleo de todas
  las variantes; usar la documentación de cada peso.
- Black Venom: el [sell sheet oficial](https://www.motivbowling.com/userfiles/filemanager/62uvavswi1n2rd08tbtl)
  se indexa con RG «.247» para 15 lb; la tabla HTML oficial ofrece **2.47**.
  No corregir por intuición: registrar la discrepancia y usar la tabla con
  procedencia explícita, pendiente de revisión directa.
- La ficha Venom Shock contiene un párrafo que nombra Hyper Venom. No mezclar
  fichas ni tomar ese párrafo como prueba de identidad. La ficha Venom Shock
  Pearl contiene reseñas con cifras distintas: usar su tabla técnica (.035 a
  15 lb), no el comentario de un comprador (.034).
- IDOL y BVP Sidewinder tienen acabados que necesitan contraste. Hy-Road puede
  tener acabados oficiales de distintas épocas: investigar variante/revisión
  antes de atribuir uno a toda la historia del producto.
- [Reckoning](https://hammerbowling.com/products/reckoning) anuncia lanzamiento
  **19-11-2026**, posterior a esta consulta. Queda fuera de los 30 candidatos;
  aparecer en portada no demuestra que ya esté comercializada.
- «Sin ASY publicado» se representa con `null`, nunca con cero deducido de un
  nombre de núcleo. «Peso disponible» no implica disponer de RG para ese peso.
- Fecha de aprobación USBC/PBA, fecha de PDF y fecha de rastreo no sustituyen
  a fecha de lanzamiento. Año no verificado: `releaseYear: null`.

## Encaje en el esquema existente sin migración

Se conserva `schemaVersion: 1` y el contrato de `CatalogSnapshot`/`CatalogBall`.
No hacen falta cambios en Hive, Firestore o el JSON personal para este piloto.

| Dato investigado | Campo existente / criterio |
| --- | --- |
| Identidad de producto | `id` estable de la tabla, `manufacturer`, `model`, `aliases`; no reutilizar un ID para un producto sucesor, variante regional o reedición diferente |
| Año y estado | `releaseYear` nullable; `status: current/discontinued/unknown` con evidencia de estado; no confundir agotada con descatalogada |
| Cubierta / núcleo / acabado | `coverType`, `coverMaterial`, `coreName`, `coreType`, `factoryFinish`; desconocidos `null`, conservar nomenclatura verificada |
| Variantes | `weights[]`: `weightLbs`, `rgInches`, `differentialInches`, `intermediateDifferentialInches`, y núcleo por peso cuando se documente; ninguna extrapolación |
| Fuente por campo | `sources[]` con `kind: manufacturer`, URL y `checkedAt` UTC; `fieldSources` como `weights.15.rgInches`, `factoryFinish`, `status`, `releaseYear`; las claves de peso son nominales, no posiciones del array |
| Foto | `photo: null`; alternativa visual existente. No poner permisos ficticios ni URLs de imágenes sin autorización |
| Versiones | `version` del snapshot aumenta cuando se apruebe una edición; `updatedAt` es revisión editorial de Bolómetro, no fecha de actualización prometida por fabricante |

El parser valida estructura, URLs, IDs únicos, pesos y referencias de fuentes,
pero **no prueba veracidad, vigencia o licencia**, ni exige todavía procedencia
para cada campo técnico. Antes de publicar se necesita revisión editorial
adicional de todos los campos no nulos, incluidas discrepancias y permisos.
No se endurece el parser en esta investigación para no romper cachés v1.

El registro personal continúa con ID propio y admite varias unidades del mismo
modelo. Los IDs propuestos no reemplazan IDs de bolas, sesiones o mantenimientos.
No se añade un vínculo persistente comercial al payload de respaldo de fase A.

## Obtención, actualización y decisiones pendientes

1. Revisar contigo estos 30 candidatos y sustituir los que no interesen.
   Si se priorizan modelos disponibles, reconfirmar estados desconocidos o
   reemplazarlos por modelos con presencia actual documentada. No etiquetarlos
   como actuales solo por antigüedad, reseñas o stock de un comercio.
2. Confirmar condiciones con Storm/Roto Grip, Brunswick/Hammer y MOTIV:
   permiso para elaborar y distribuir una selección de especificaciones,
   existencia de feed/CSV/API documentada, cuotas, atribución, variantes y
   forma de comunicar correcciones. Fotografías se consultan por separado:
   app comercial, CDN propio o del titular, transformación y caché sin conexión,
   alcance temporal/territorial y retirada del permiso.
3. Para la selección aprobada, transcribir manualmente únicamente campos
   comprobados y cada fila por peso, con revisión cruzada HTML/PDF. Registrar
   SKU como evidencia editorial; no convertirlo automáticamente en ID personal.
   Resolver acabados contradictorios o dejarlos `null` con incidencia documentada.
4. Validar un snapshot de prepublicación con el parser v1, revisión editorial
   campo por campo y pruebas de catálogo/búsqueda/selección ya existentes.
   Mantener separados fixtures y datos reales; no convertir fixtures en modelos.
5. Tras otra autorización, decidir dónde alojar JSON e imágenes autorizadas.
   El repositorio actual tiene abstracción de actualización, pero no se activa
   ningún servidor, URL remota ni despliegue en este trabajo.
6. Proponer revisión editorial mensual y antes de publicar altas/retiradas;
   conservar IDs, aumentar versión y mantener caché anterior si falla descarga
   o validación. Una corrección comercial nunca modifica una bola personal
   existente. Retirar una foto no debe eliminar fichas ni historiales personales.

Pendiente de aprobación: selección, política de publicación con campos
desconocidos, condiciones de uso/permiso de datos y proveedor/alojamiento futuro.
No hay costes contratados, dependencias instaladas ni autorización fotográfica
confirmada. No se contactó con terceros.

## Validación local

Se añaden pruebas sintéticas en `test/catalog_c1_contract_test.dart`: valores
desconocidos, variantes de núcleo/peso, procedencia por medición, identidad
estable frente a cambio de URL, modelos con nombres iguales pero ID diferente,
rechazo de autorización fotográfica incompleta y preservación de datos en JSON.
No validan afirmaciones comerciales de esta selección ni derechos de terceros.

Comando reproducible (sin red ni cuentas Firebase):

```powershell
flutter test --no-pub test/catalog_ball_test.dart test/ball_catalog_repository_test.dart test/catalog_flow_test.dart test/catalog_c1_contract_test.dart
```

Resultado: **40 pruebas superadas, 0 fallos** (34 existentes y 6 nuevas).
`flutter analyze --no-pub test/catalog_c1_contract_test.dart`: **sin incidencias**.
Se aplicó formato Dart al test nuevo. El formateador aislado avisó de que no
resolvía el include `flutter_lints`; el análisis posterior con Flutter sí terminó
correctamente. La ejecución restringida inicial no pudo escribir en las cachés
externas del SDK; se detuvieron sus procesos de espera y la ejecución local con
acceso a esas cachés completó las comprobaciones sin instalar dependencias.
El seed comercial integrado sigue sin productos; los fixtures siguen siendo
ficticios y optativos. No se modifican interfaz, Firebase, respaldo o modelos
personales, ni se toca Bolómetro Vision.
