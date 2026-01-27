import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import '../l10n/app_localizations.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'utils/app_constants.dart';

import 'models/partida.dart';
import 'models/sesion.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home.dart';
import 'screens/registro_sesion.dart';
import 'screens/login_screen.dart';

import 'models/perfil_usuario.dart';
import 'services/auth_service.dart';
import 'services/analytics_service.dart';
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

  Hive.registerAdapter(PartidaAdapter());
  Hive.registerAdapter(SesionAdapter());
  Hive.registerAdapter(PerfilUsuarioAdapter());
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
