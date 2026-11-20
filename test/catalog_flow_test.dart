import 'dart:typed_data';
import 'package:bolometro/repositories/ball_media_repository.dart';
import 'package:bolometro/screens/editar_bola_screen.dart';
import 'package:bolometro/models/catalog_selection.dart';
import 'package:bolometro/widgets/ball_photo.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/models/bowling_ball.dart';
import 'package:bolometro/models/catalog_ball.dart';
import 'package:bolometro/config/catalog_config.dart';
import 'package:bolometro/models/nota.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/perfil_usuario.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/repositories/ball_catalog_repository.dart';
import 'package:bolometro/services/ball_stats_service.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/screens/mis_bolas_screen.dart';
import 'package:bolometro/screens/ball_catalog_screen.dart';
import 'package:bolometro/widgets/catalog_ball_image.dart';
import 'package:bolometro/utils/app_constants.dart';
import 'support/catalog_fixtures.dart';
import 'support/memory_arsenal_store.dart';
import 'support/test_firestore_service.dart';

class ObservedArsenal extends DataRepository {
  BowlingBall? lastSaved;
  ObservedArsenal(
    MemoryArsenalStore backup, {
    TestFirestoreService? firestoreService,
  }) : super(
         firestoreService: firestoreService ?? TestFirestoreService(),
         arsenalRemote: backup,
         arsenalBackupEnabled: true,
         autoSyncArsenal: false,
       );
  @override
  Future<BowlingBall> crearBola(BowlingBall ball) async {
    final saved = await super.crearBola(ball);
    lastSaved = saved;
    return saved;
  }
}

class OfflineSessionsFirestore extends TestFirestoreService {
  @override
  Future<List<Sesion>> obtenerSesiones(String userId) async =>
      throw StateError('Simulated session network failure');
}

void main() {
  late Directory temp;
  late ObservedArsenal arsenal;
  late MemoryArsenalStore backup;
  late BallCatalogRepository catalog;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('bolometro_catalog_flow_');
    Hive.init(temp.path);
    void register<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId))
        Hive.registerAdapter<T>(adapter);
    }

    register(PartidaAdapter());
    register(SesionAdapter());
    register(NotaAdapter());
    register(NotaAdjuntoAdapter());
    register(PerfilUsuarioAdapter());
    register(BowlingBallAdapter());
    register(BallMaintenanceAdapter());
    await Hive.openBox<Sesion>(AppConstants.boxSesiones);
    await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
    await Hive.openBox<Nota>(AppConstants.boxNotas);
    await Hive.openBox<BowlingBall>(AppConstants.boxBolas);
    await Hive.openBox<BallMaintenance>(AppConstants.boxMantenimientosBolas);
    backup = MemoryArsenalStore();
    arsenal = ObservedArsenal(backup);
    catalog = memoryCatalog();
    await arsenal.setUser('fictional-account');
  });
  tearDown(() async {
    arsenal.dispose();
    catalog.dispose();
    await Hive.close();
    await temp.delete(recursive: true);
  });
  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<DataRepository>.value(value: arsenal),
      ChangeNotifierProvider<BallCatalogRepository>.value(value: catalog),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets('catalog seed is empty and demo is explicitly opt-in', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(BallCatalogScreen(repository: catalog)));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Todavía no hay modelos comerciales'),
      findsOneWidget,
    );
    expect(find.text('Órbita Solid (ficticia)'), findsNothing);
    await tester.tap(find.text('Ver demostración con datos ficticios'));
    await tester.pumpAndSettle();
    expect(find.textContaining('DEMOSTRACIÓN'), findsOneWidget);
    expect(find.text('Órbita Solid (ficticia)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'alfa orbita');
    await tester.pumpAndSettle();
    expect(find.text('Órbita Solid (ficticia)'), findsOneWidget);
    expect(find.text('Archivo Pearl (ficticia)'), findsNothing);
    await tester.tap(find.text('Salir de demostración'));
    await tester.pumpAndSettle();
    expect(find.text('Órbita Solid (ficticia)'), findsNothing);
    expect(catalog.snapshot!.balls, isEmpty);
  });

  testWidgets('unverified photo renders a placeholder and no network image', (
    tester,
  ) async {
    final photo = CatalogPhoto.fromJson({
      'url': 'https://example.invalid/unauthorized.png',
    });
    await tester.pumpWidget(MaterialApp(home: CatalogBallImage(photo: photo)));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/logo_bolometro_min.png',
    );
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('catalog assets are available through Flutter bundle', (
    tester,
  ) async {
    final bundled = BallCatalogRepository(cache: MemoryCatalogCache());
    await tester.runAsync(() async {
      expect(
        (await bundled.load()).balls.length,
        CatalogConfig.commercialEnabled ? 28 : 0,
      );
      expect((await bundled.demonstration()).balls, hasLength(3));
    });
    bundled.dispose();
  });

  testWidgets('filters remain scrollable on a small screen with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(wrap(BallCatalogScreen(repository: catalog)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver demostración con datos ficticios'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<CommercialStatus>),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disabled catalog opens manual entry directly without changing arsenal',
    (tester) async {
      final ball = BowlingBall(
        id: 'preserved-manual-only',
        name: 'Existing ball',
        weightLbs: 14,
      );
      await tester.runAsync(() => arsenal.crearBola(ball));
      catalog.dispose();
      catalog = memoryCatalog(enabled: false);
      await tester.pumpWidget(wrap(const MisBolasScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Agregar bola'));
      await tester.pumpAndSettle();
      expect(find.byType(EditarBolaScreen), findsOneWidget);
      expect(find.byType(BallCatalogScreen), findsNothing);
      expect(find.text('Buscar en cat\u00e1logo'), findsNothing);
      expect(find.text('Vincular modelo para fotograf\u00eda'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final saved = await arsenal.listarTodasLasBolas();
      expect(saved.map((b) => b.toJson()).toList(), [ball.toJson()]);
    },
  );

  testWidgets(
    'manual entry remains available and cancelling add has no side effects',
    (tester) async {
      await tester.pumpWidget(wrap(const MisBolasScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Agregar bola'));
      await tester.pumpAndSettle();
      expect(find.text('Buscar en catálogo'), findsOneWidget);
      expect(find.text('Añadir manualmente'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(await arsenal.listarTodasLasBolas(), isEmpty);
      await tester.tap(find.byTooltip('Agregar bola'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir manualmente'));
      await tester.pumpAndSettle();
      expect(find.text('Agregar Bola'), findsOneWidget);
      expect(find.text('Datos precargados del catálogo.'), findsNothing);
    },
  );

  testWidgets(
    'two units from one model keep legacy records and phase A payload unchanged',
    (tester) async {
      final legacy = BowlingBall(
        id: 'legacy-ball',
        name: 'Legacy ball',
        weightLbs: 14.5,
        notes: 'Keep me',
      );
      await tester.runAsync(() async {
        await arsenal.crearBola(legacy);
        await arsenal.crearMantenimiento(
          BallMaintenance(id: 'legacy-maintenance', ballId: legacy.id),
        );
        await Hive.box<Sesion>(arsenal.sesionesBoxName).add(
          Sesion(
            fecha: DateTime(2020, 1, 1),
            lugar: 'Test',
            tipo: AppConstants.tipoEntrenamiento,
            partidas: [Partida(total: 150, frames: [], ballId: legacy.id)],
          ),
        );
      });
      await tester.pumpWidget(wrap(const MisBolasScreen()));
      await tester.pumpAndSettle();
      final ids = <String>[];
      for (var unit = 1; unit <= 2; unit++) {
        await tester.tap(find.byTooltip('Agregar bola'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Buscar en catálogo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver demostración con datos ficticios'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Órbita Solid (ficticia)'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(DropdownButtonFormField<int>),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15 lb').last);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Añadir a mi arsenal'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Añadir a mi arsenal'));
        await tester.pumpAndSettle();
        expect(find.text('Añadir una bola ficticia'), findsOneWidget);
        await tester.tap(find.text('Continuar con la prueba'));
        await tester.pumpAndSettle();
        expect(find.text('[PRUEBA] Órbita Solid (ficticia)'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.widgetWithText(TextFormField, 'Coverstock'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Material de prueba Alfa'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.widgetWithText(TextFormField, 'Notas'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Notas'),
          'Personal unit $unit',
        );
        await tester.scrollUntilVisible(
          find.text('Guardar'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        arsenal.lastSaved = null;
        await tester.runAsync(() async {
          final button = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Guardar'),
          );
          await (button.onPressed! as Future<void> Function())().timeout(
            const Duration(seconds: 5),
          );
          expect(arsenal.lastSaved, isNotNull);
          ids.add(arsenal.lastSaved!.id);
        });
        await tester.pumpAndSettle();
        expect(find.text('Mis Bolas'), findsOneWidget);
      }
      expect(ids.toSet(), hasLength(2));
      expect(ids, isNot(contains('fixture.orbita-solid')));
      await tester.runAsync(() async {
        final all = await arsenal.listarTodasLasBolas();
        expect(all, hasLength(3));
        expect(
          (await arsenal.obtenerBola(legacy.id))!.toJson(),
          legacy.toJson(),
        );
        expect(
          (await arsenal.listarMantenimientosPorBola(legacy.id)).single.id,
          'legacy-maintenance',
        );
        expect(
          Hive.box<Sesion>(
            arsenal.sesionesBoxName,
          ).values.single.partidas.single.ballId,
          legacy.id,
        );
        await arsenal.sincronizarArsenal();
        final personal =
            backup.records['fictional-account/balls/${ids.first}']!.payload;
        expect(personal.keys.toSet(), legacy.toJson().keys.toSet());
        expect(personal['notes'], 'Personal unit 1');
        expect(personal['weightLbs'], 15);
        expect(personal.containsKey('catalogId'), isFalse);
      });
    },
  );

  testWidgets(
    'C3 real model creates personal units without altering legacy history',
    (tester) async {
      arsenal.dispose();
      arsenal = ObservedArsenal(
        backup,
        firestoreService: OfflineSessionsFirestore(),
      );
      await tester.runAsync(() => arsenal.setUser('fictional-account'));
      catalog.dispose();
      catalog = BallCatalogRepository(
        commercialCatalogEnabled: true,
        cache: MemoryCatalogCache(),
        loadSeed: () async => File(
          'docs/catalog/c2/catalog_real_v2.review.json',
        ).readAsStringSync(),
      );
      final legacy = BowlingBall(
        id: 'c3-legacy-ball',
        name: 'Existing unit',
        weightLbs: 14,
        notes: 'Unchanged',
      );
      final session = Sesion(
        fecha: DateTime(2020, 1, 1),
        lugar: 'Fictitious centre',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(total: 150, frames: [], ballId: legacy.id),
          Partida(total: 200, frames: [], ballId: legacy.id),
        ],
      );
      final originalSession = jsonDecode(jsonEncode(session.toJson()));
      final originalBall = legacy.toJson();
      await tester.runAsync(() async {
        await arsenal.crearBola(legacy);
        await arsenal.crearMantenimiento(
          BallMaintenance(id: 'c3-legacy-maintenance', ballId: legacy.id),
        );
        await Hive.box<Sesion>(
          arsenal.sesionesBoxName,
        ).put('c3-legacy-session', session);
      });
      await tester.pumpWidget(wrap(const MisBolasScreen()));
      await tester.pumpAndSettle();
      final personalIds = <String>[];
      for (var unit = 1; unit <= 2; unit++) {
        await tester.tap(find.byTooltip('Agregar bola'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Buscar en catálogo'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Storm Phaze V');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Phaze V'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Phaze V'));
        await tester.pumpAndSettle();
        final weight = find.byType(DropdownButtonFormField<int>);
        await tester.scrollUntilVisible(
          weight,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(weight);
        await tester.pumpAndSettle();
        await tester.tap(find.text('15 lb').last);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Añadir a mi arsenal'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Añadir a mi arsenal'));
        await tester.pumpAndSettle();
        expect(find.text('Guardar desde catálogo en revisión'), findsNothing);
        await tester.scrollUntilVisible(
          find.widgetWithText(TextFormField, 'Acabado (finish)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final finish = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Acabado (finish)'),
        );
        expect(
          finish.controller!.text,
          isEmpty,
        ); // No invented default for null.
        await tester.scrollUntilVisible(
          find.widgetWithText(TextFormField, 'Notas'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Notas'),
          'Fictitious C3 unit $unit',
        );
        await tester.scrollUntilVisible(
          find.text('Guardar'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.runAsync(() async {
          final save = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Guardar'),
          );
          await (save.onPressed! as Future<void> Function())();
          personalIds.add(arsenal.lastSaved!.id);
        });
        await tester.pumpAndSettle();
      }
      await tester.runAsync(() async {
        expect(personalIds.toSet(), hasLength(2));
        expect(personalIds, isNot(contains('storm.phaze-v')));
        expect((await arsenal.obtenerBola(legacy.id))!.toJson(), originalBall);
        expect(
          Hive.box<Sesion>(
            arsenal.sesionesBoxName,
          ).get('c3-legacy-session')!.toJson(),
          originalSession,
        );
        expect(
          (await arsenal.listarMantenimientosPorBola(legacy.id)).single.id,
          'c3-legacy-maintenance',
        );
        final stats = BallStatsService.calcular(
          await arsenal.obtenerPartidasPorBola(legacy.id),
        );
        expect(stats.partidasJugadas, 2);
        expect(stats.promedio, 175);
        expect(stats.mejorPartida, 200);
        await arsenal.sincronizarArsenal();
        final payload = backup
            .records['fictional-account/balls/${personalIds.first}']!
            .payload;
        expect(payload.keys.toSet(), originalBall.keys.toSet());
        expect(payload['finish'], isNull);
        expect(payload.containsKey('catalogId'), isFalse);
      });
    },
  );

  testWidgets(
    'C4 linking preserves personal photo, IDs and maintenance in the normal form',
    (tester) async {
      final ball = BowlingBall(
        id: 'c4-existing',
        name: 'Existing unit',
        weightLbs: 15,
      );
      late BallMediaRepository media;
      late Map<String, dynamic> before;
      final file = File('${temp.path}/synthetic.png');
      await tester.runAsync(() async {
        media = PreviewMedia(documentsDirectory: () async => temp);
        addTearDown(media.dispose);
        await arsenal.crearBola(ball);
        await arsenal.crearMantenimiento(
          BallMaintenance(id: 'c4-maintenance', ballId: ball.id),
        );
        await file.writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aV1cAAAAASUVORK5CYII=',
          ),
        );
        await media.save(
          uid: 'fictional-account',
          ballId: ball.id,
          personalPath: file.path,
        );
        before = await media.metadata('fictional-account', ball.id);
      });

      catalog.dispose();
      catalog = BallCatalogRepository(
        commercialCatalogEnabled: true,
        cache: MemoryCatalogCache(),
        loadSeed: () async =>
            File('docs/catalog/c2/catalog_real_v2.review.json').readAsStringSync(),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<BallMediaRepository>.value(
          value: media,
          child: wrap(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarBolaScreen(ball: ball),
                    ),
                  ),
                  child: const Text('Open existing ball'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open existing ball'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BallPhoto), findsOneWidget);
      await tester.tap(find.text('Vincular modelo para fotografía'));
      await tester.pumpAndSettle();
      expect(find.text('Añadir manualmente'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Storm Phaze II');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Phaze II'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Phaze II'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Guardar'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.runAsync(() async {
        final save = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Guardar'),
        );
        await (save.onPressed! as Future<void> Function())();
        final after = await media.metadata('fictional-account', ball.id);
        expect(after['catalogId'], 'storm.phaze-ii');
        expect(after['personalFile'], before['personalFile']);
        expect((await arsenal.obtenerBola(ball.id))!.toJson()['id'], ball.id);
        expect(
          (await arsenal.listarMantenimientosPorBola(ball.id)).single.id,
          'c4-maintenance',
        );
        expect(
          (await arsenal.obtenerBola(
            ball.id,
          ))!.toJson().containsKey('catalogId'),
          isFalse,
        );
      });
      await tester.pumpAndSettle();
      expect(find.text('Open existing ball'), findsOneWidget);
    },
  );

  testWidgets(
    'C4 image metadata error does not undo or duplicate an already saved ball',
    (tester) async {
      final media = FailingMedia();
      addTearDown(media.dispose);
      final selection = CatalogSelection(
        (await catalog.demonstration()).balls.first,
        15,
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<BallMediaRepository>.value(
          value: media,
          child: wrap(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditarBolaScreen(catalogSelection: selection),
                    ),
                  ),
                  child: const Text('Open new ball'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open new ball'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Guardar'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.runAsync(() async {
        final save = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Guardar'),
        );
        await (save.onPressed! as Future<void> Function())();
      });
      await tester.pumpAndSettle();
      expect(find.text('Open new ball'), findsOneWidget);
      expect(
        find.text('Bola guardada. No se pudo guardar su imagen local.'),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        expect(await arsenal.listarTodasLasBolas(), hasLength(1));
      });
    },
  );

  test(
    'Hive cache uses its own box and restores a downloaded snapshot',
    () async {
      final repository = BallCatalogRepository(
        commercialCatalogEnabled: true,
        cache: HiveCatalogCache(),
        loadSeed: () async => catalogSeed(),
      );
      await repository.install(simulatedCatalog(2));
      repository.dispose();
      await Hive.box<String>(HiveCatalogCache.boxName).close();
      final reopened = BallCatalogRepository(
        commercialCatalogEnabled: true,
        cache: HiveCatalogCache(),
        loadSeed: () async => catalogSeed(),
      );
      expect((await reopened.load()).version, 2);
      expect(await arsenal.listarTodasLasBolas(), isEmpty);
      reopened.dispose();
    },
  );
}

class FailingMedia extends BallMediaRepository {
  @override
  Future<void> save({
    required String? uid,
    required String ballId,
    String? catalogId,
    String? personalPath,
  }) async {
    throw const FileSystemException('Synthetic full disk');
  }
}

// Deterministic UI bytes; real file persistence/priority is covered in ball_media_test.
class PreviewMedia extends BallMediaRepository {
  PreviewMedia({required super.documentsDirectory});
  @override
  Future<Uint8List?> resolve({
    String? uid,
    String? ballId,
    String? catalogId,
    String? draftPersonalPath,
  }) async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aV1cAAAAASUVORK5CYII=',
  );
}
