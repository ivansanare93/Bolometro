import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/screens/registro_completo_sesion.dart';
import 'package:bolometro/screens/temporadas_screen.dart';
import 'package:bolometro/services/analytics_service.dart';
import 'package:bolometro/services/season_assignment_store.dart';
import 'package:bolometro/services/temporada_service.dart';
import 'package:bolometro/widgets/season_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_arsenal_store.dart';
import 'support/test_firestore_service.dart';

class _Repository extends DataRepository {
  final List<Sesion> sessions = [];
  int assignments = 0;
  _Repository()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  @override
  Future<List<Sesion>> obtenerSesiones() async => sessions.toList();
  @override
  Future<SeasonAssignmentResult> estadoCambiosTemporada() async =>
      const SeasonAssignmentResult();
  @override
  Future<SeasonAssignmentResult> asignarTemporadaEnLote(
    List<Sesion> selected,
    String? destination, {
    bool allowArchived = false,
  }) async {
    assignments++;
    for (final s in selected) {
      final index = sessions.indexOf(s);
      sessions[index] = s.copyWith(
        temporada: destination,
        clearTemporada: destination == null,
      );
    }
    return SeasonAssignmentResult(updated: selected.length);
  }
}

class _Analytics implements AnalyticsService {
  @override
  Future<void> logScreenView(String screenName) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(Widget child, _Repository repo) => MultiProvider(
  providers: [
    ChangeNotifierProvider<DataRepository>.value(value: repo),
    Provider<AnalyticsService>.value(value: _Analytics()),
  ],
  child: MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  late _Repository repo;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _Repository();
  });
  tearDown(() => repo.dispose());

  testWidgets(
    'registration honors explicit no-season and filters archived choices',
    (tester) async {
      await TemporadaService.addTemporada('Archived');
      await TemporadaService.archiveTemporada('Archived');
      await TemporadaService.addTemporada('Available');
      await TemporadaService.setTemporadaActiva(null);
      await tester.pumpWidget(app(const RegistroCompletoSesionScreen(), repo));
      await tester.pumpAndSettle();
      final selector = tester.widget<SeasonSelector>(
        find.byType(SeasonSelector),
      );
      expect(normalizeSeason(selector.value), isNull);
      await tester.tap(
        find.descendant(
          of: find.byType(SeasonSelector),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Archived'), findsNothing);
      expect(find.text('Available'), findsWidgets);
      await tester.tap(find.text('Available').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<SeasonSelector>(find.byType(SeasonSelector)).value,
        'Available',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(SeasonSelector),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sin temporada').last);
      await tester.pumpAndSettle();
      expect(
        normalizeSeason(
          tester.widget<SeasonSelector>(find.byType(SeasonSelector)).value,
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'draft season takes precedence over default including archived history',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'temporada_activa': 'Default',
        'temporadas_list': '["Default","Archived"]',
        'temporadas_archivadas': '["Archived"]',
        'draft_sesion_completa':
            '{"lugar":"Test","temporada":"Archived","partidas":[]}',
      });
      await tester.pumpWidget(app(const RegistroCompletoSesionScreen(), repo));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SeasonSelector>(find.byType(SeasonSelector)).value,
        'Archived',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new names are registered and existing names reused without duplicates',
    (tester) async {
      String? value;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SeasonSelector(
                value: value,
                seasons: const [],
                archived: const {},
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
          repo,
        ),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  Liga nueva  ');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(value, 'Liga nueva');
      expect(await TemporadaService.getTemporadas(), ['Liga nueva']);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'liga nueva');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(value, 'Liga nueva');
      expect(await TemporadaService.getTemporadas(), ['Liga nueva']);
    },
  );

  testWidgets('archived season cannot be recreated through custom text', (
    tester,
  ) async {
    var changed = false;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: SeasonSelector(
            value: null,
            seasons: const ['Archived'],
            archived: const {'Archived'},
            onChanged: (_) => changed = true,
          ),
        ),
        repo,
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'archived');
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(changed, isFalse);
    expect(find.textContaining('Restaura la temporada'), findsOneWidget);
  });

  testWidgets(
    'renaming previews session count and cancellation changes nothing',
    (tester) async {
      await TemporadaService.addTemporada('Liga');
      repo.sessions.add(
        Sesion(
          fecha: DateTime(2026),
          lugar: 'Test',
          tipo: 'Entrenamiento',
          partidas: [],
          temporada: 'Liga',
        ),
      );
      await tester.pumpWidget(app(const TemporadasScreen(), repo));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is PopupMenuItem<String> && widget.value == 'rename',
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Liga nueva');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Liga nueva'), findsWidgets);
      expect(repo.assignments, 0);
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();
      expect(repo.assignments, 0);
      expect(repo.sessions.single.temporada, 'Liga');
      // Confirming the same operation updates the session and metadata together.
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar').last);
      await tester.pumpAndSettle();
      expect(repo.assignments, 1);
      expect(repo.sessions.single.temporada, 'Liga nueva');
      expect(await TemporadaService.getTemporadas(), ['Liga nueva']);
    },
  );
  testWidgets('removal requires two confirmations and keeps the session', (
    tester,
  ) async {
    await TemporadaService.addTemporada('Liga');
    repo.sessions.add(
      Sesion(
        fecha: DateTime(2026),
        lugar: 'Test',
        tipo: 'Entrenamiento',
        partidas: [],
        temporada: 'Liga',
      ),
    );
    await tester.pumpWidget(app(const TemporadasScreen(), repo));
    await tester.pumpAndSettle();
    Future<void> openRemoval() async {
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is PopupMenuItem<String> && widget.value == 'delete',
        ),
      );
      await tester.pumpAndSettle();
    }

    await openRemoval();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.assignments, 0);
    expect(repo.sessions.single.temporada, 'Liga');
    await openRemoval();
    await tester.tap(find.text('Eliminar y reasignar'));
    await tester.pumpAndSettle();
    expect(repo.assignments, 0);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(repo.sessions.length, 1);
    expect(repo.sessions.single.temporada, isNull);
    expect(await TemporadaService.getTemporadas(), isEmpty);
  });
}
