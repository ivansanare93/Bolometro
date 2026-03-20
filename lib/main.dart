import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'l10n/app_localizations.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'utils/app_constants.dart';

import 'models/partida.dart';
import 'models/sesion.dart';
import 'models/nota.dart';
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
import 'services/integrity_service.dart';
import 'services/notification_service.dart';
import 'repositories/data_repository.dart';
import 'utils/estadisticas_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();

  // Activar Firebase App Check (Google Play Integrity en Android)
  // para proteger los servicios de Firebase frente a accesos no autorizados.
  await IntegrityService().activate();
  
  // Configurar manejador de mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
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
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(NotaAdapter());
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
  
  // Abrir boxes por defecto para modo offline (sin usuario autenticado)
  // Los boxes específicos de usuario se abrirán cuando se autentique
  await Hive.openBox<Sesion>(AppConstants.boxSesiones);
  await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
  await Hive.openBox<Nota>(AppConstants.boxNotas);

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
  String? _lastSetUserId;
  bool _notificationsInitialized = false;
  bool _initializingNotifications = false;

  void _onContinueWithoutLogin() {
    setState(() {
      _skipLogin = true;
      _hasShownLoginScreen = true;
    });
  }

  Future<void> _initializeNotifications(String userId, {String? languageCode}) async {
    if (!_notificationsInitialized && !_initializingNotifications) {
      _initializingNotifications = true;
      try {
        final notificationService = NotificationService();
        await notificationService.initialize();
        await notificationService.saveUserToken(userId, languageCode: languageCode);
        _notificationsInitialized = true;
      } finally {
        _initializingNotifications = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);

    // Detect when the user logs out (userId changes from something to null)
    if (_previousUserId != null && authService.userId == null) {
      // Update previous user ID first to prevent multiple callbacks
      _previousUserId = authService.userId;
      _lastSetUserId = null; // Reset so the next login re-triggers setUser
      _notificationsInitialized = false;
      // User logged out, reset flags to allow new login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _hasShownLoginScreen = false;
          _skipLogin = false;
        });
      });
    } else {
      // Update previous user ID for normal state changes
      _previousUserId = authService.userId;
    }

    // Sincronizar estado de autenticación con el repositorio solo cuando
    // cambia el userId para evitar llamadas repetidas en cada rebuild.
    if (authService.isAuthenticated &&
        authService.userId != null &&
        authService.userId != _lastSetUserId) {
      _lastSetUserId = authService.userId;
      // Use scheduleMicrotask to avoid blocking the build method
      // Errors are caught and logged to prevent silent failures
      Future.microtask(() async {
        try {
          await dataRepository.setUser(authService.userId);
          // Update AchievementService to use the user-specific sessions box
          if (context.mounted) {
            Provider.of<AchievementService>(context, listen: false)
                .updateSesionesBoxName(dataRepository.sesionesBoxName);
          }
        } catch (e) {
          debugPrint('Error setting user in repository: $e');
        }
      });
      // Inicializar notificaciones para usuario autenticado
      _initializeNotifications(
        authService.userId!,
        languageCode: Provider.of<LanguageProvider>(context, listen: false).locale.languageCode,
      );
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
