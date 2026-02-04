import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'utils/app_constants.dart';

import 'models/partida.dart';
import 'models/sesion.dart';
import 'models/friend.dart';
import 'models/friend_request.dart';
import 'models/achievement.dart';
import 'models/user_progress.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home.dart';
import 'screens/registro_sesion.dart';
import 'screens/login_screen.dart';

import 'models/perfil_usuario.dart';
import 'services/auth_service.dart';
import 'services/analytics_service.dart';
import 'services/achievement_service.dart';
import 'repositories/data_repository.dart';
import 'utils/estadisticas_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Inicializar Hive
  await Hive.initFlutter();

  // Borra las boxes (¡esto elimina todas las partidas y sesiones!)
  /*await Hive.deleteBoxFromDisk('partidas');
  await Hive.deleteBoxFromDisk('sesiones');*/

  // Registrar adapters solo si no están ya registrados
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PartidaAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SesionAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(PerfilUsuarioAdapter());
  }
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(FriendAdapter());
  }
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(FriendRequestAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(AchievementAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(AchievementTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(AchievementRarityAdapter());
  }
  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(UserProgressAdapter());
  }
  await Hive.openBox<Sesion>(AppConstants.boxSesiones);
  await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DataRepository()),
        ChangeNotifierProvider(create: (_) => EstadisticasCache()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
        Provider(create: (_) => AnalyticsService()),
      ],
      child: const BolosApp(),
    ),
  );
}

class BolosApp extends StatelessWidget {
  const BolosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    return MaterialApp(
      title: 'Bolómetro',
      theme: AppTheme.azul,
      darkTheme: AppTheme.oscuro,
      themeMode: themeProvider.themeMode,
      locale: languageProvider.locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [analyticsService.getAnalyticsObserver()],
      home: const AuthWrapper(),
      routes: {
        AppConstants.rutaRegistro: (_) => RegistroSesionScreen(
          onGuardar: (partida) {
            // Aquí puedes manejar cómo guardar la partida
            // TODO: Implementar manejo de guardado desde ruta
          },
        ),
      },
    );
  }
}

/// Widget que envuelve la aplicación y gestiona el estado de autenticación
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasShownLoginScreen = false;
  bool _skipLogin = false;
  String? _previousUserId;

  void _onContinueWithoutLogin() {
    setState(() {
      _skipLogin = true;
      _hasShownLoginScreen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);

    // Detectar cuando el usuario cierra sesión (userId cambia de algo a null)
    if (_previousUserId != null && authService.userId == null) {
      // Usuario cerró sesión, resetear los flags para permitir nuevo login
      _hasShownLoginScreen = false;
      _skipLogin = false;
    }
    _previousUserId = authService.userId;

    // Sincronizar estado de autenticación con el repositorio
    if (authService.isAuthenticated && authService.userId != null) {
      dataRepository.setUser(authService.userId);
    }

    // Mostrar pantalla de login solo la primera vez si no está autenticado y no se ha saltado
    if (!_hasShownLoginScreen && !authService.isAuthenticated && !_skipLogin) {
      return LoginScreen(
        onContinueWithoutLogin: _onContinueWithoutLogin,
      );
    }

    // Si el usuario inicia sesión o continúa sin autenticarse, marcar como visto
    if (!_hasShownLoginScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _hasShownLoginScreen = true;
        });
      });
    }

    // Usuario autenticado o continuó sin autenticarse: mostrar pantalla principal
    return const HomeScreen();
  }
}
