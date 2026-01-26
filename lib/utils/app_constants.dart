/// Constantes de la aplicación Bolómetro
/// 
/// Este archivo centraliza todas las constantes utilizadas en la aplicación
/// para mejorar la mantenibilidad y evitar errores de tipografía.

class AppConstants {
  // Prevenir instanciación
  AppConstants._();

  // ===== Tipos de Sesión =====
  static const String tipoTodos = 'Todos';
  static const String tipoEntrenamiento = 'Entrenamiento';
  static const String tipoCompeticion = 'Competición';

  // Lista de tipos de sesión para filtros
  static const List<String> tiposSesionConTodos = [
    tipoTodos,
    tipoEntrenamiento,
    tipoCompeticion,
  ];

  // Lista de tipos de sesión sin "Todos" (para selectores)
  static const List<String> tiposSesion = [
    tipoEntrenamiento,
    tipoCompeticion,
  ];

  // ===== Nombres de Boxes de Hive =====
  static const String boxSesiones = 'sesiones';
  static const String boxPerfilUsuario = 'perfilUsuario';

  // ===== Configuración de UI =====
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double defaultElevation = 2.0;
  static const double cardElevation = 3.0;

  // ===== Límites y Validaciones =====
  static const int maxPinesBowling = 10;
  static const int totalFrames = 10;
  static const int maxTirosPorFrame = 2;
  static const int maxTirosFrame10 = 3;

  // ===== Símbolos de Bolos =====
  static const String simboloStrike = 'X';
  static const String simboloSpare = '/';
  static const String simboloFallo = '-';

  // ===== Mensajes =====
  static const String mensajeNoHaySesiones = 'No hay sesiones registradas';
  static const String mensajeNoHayPartidas = 'No hay partidas para mostrar';
  static const String mensajeCargando = 'Cargando...';
  static const String mensajeGuardado = 'Guardado correctamente';
  static const String mensajeError = 'Ha ocurrido un error';

  // ===== Rutas de navegación =====
  static const String rutaRegistro = '/registro';
  static const String rutaHome = '/';

  // ===== Preferencias compartidas (keys) =====
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyLocale = 'locale';

  // ===== Estadísticas =====
  static const int ventanaPromedioMovil = 5; // Número de partidas para promedio móvil
  static const int maxPartidasTop = 10; // Top N mejores partidas

  // ===== Dimensiones de iconos =====
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 46.0;
}
