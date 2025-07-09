import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

import 'models/partida.dart';
import 'models/sesion.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home.dart';
import 'screens/registro_sesion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

      // Borra las boxes (¡esto elimina todas las partidas y sesiones!)
  /*await Hive.deleteBoxFromDisk('partidas');
  await Hive.deleteBoxFromDisk('sesiones');
*/

  Hive.registerAdapter(PartidaAdapter());
  Hive.registerAdapter(SesionAdapter());
  await Hive.openBox<Sesion>('sesiones');


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
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

    return MaterialApp(
      title: 'Bolómetro',
      theme: AppTheme.azul,
      darkTheme: AppTheme.oscuro,
      themeMode: themeProvider.themeMode,
      locale: languageProvider.locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
      routes: {
        '/registro': (_) => RegistroSesionScreen(
          onGuardar: (partida) {
            // Aquí puedes manejar cómo guardar la partida
            print('Partida guardada desde ruta: ${partida.total}');
          },
        ),
      },
    );
  }
}
