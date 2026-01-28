import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// El título de la aplicación
  ///
  /// In es, this message translates to:
  /// **'Bolómetro'**
  String get appTitle;

  /// Mensaje de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get welcome;

  /// Botón para iniciar sesión con Google
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get continueWithGoogle;

  /// Botón para continuar sin autenticación
  ///
  /// In es, this message translates to:
  /// **'Continuar sin iniciar sesión'**
  String get continueWithoutLogin;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @sessions.
  ///
  /// In es, this message translates to:
  /// **'Sesiones'**
  String get sessions;

  /// No description provided for @statistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statistics;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @newSession.
  ///
  /// In es, this message translates to:
  /// **'Nueva Sesión'**
  String get newSession;

  /// No description provided for @newGame.
  ///
  /// In es, this message translates to:
  /// **'Nueva Partida'**
  String get newGame;

  /// No description provided for @training.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get training;

  /// No description provided for @competition.
  ///
  /// In es, this message translates to:
  /// **'Competición'**
  String get competition;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get location;

  /// No description provided for @notes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @score.
  ///
  /// In es, this message translates to:
  /// **'Puntuación'**
  String get score;

  /// No description provided for @average.
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get average;

  /// No description provided for @bestGame.
  ///
  /// In es, this message translates to:
  /// **'Mejor Partida'**
  String get bestGame;

  /// No description provided for @totalGames.
  ///
  /// In es, this message translates to:
  /// **'Total de Partidas'**
  String get totalGames;

  /// No description provided for @strikes.
  ///
  /// In es, this message translates to:
  /// **'Strikes'**
  String get strikes;

  /// No description provided for @spares.
  ///
  /// In es, this message translates to:
  /// **'Spares'**
  String get spares;

  /// No description provided for @frames.
  ///
  /// In es, this message translates to:
  /// **'Frames'**
  String get frames;

  /// No description provided for @frame.
  ///
  /// In es, this message translates to:
  /// **'Frame'**
  String get frame;

  /// No description provided for @firstBall.
  ///
  /// In es, this message translates to:
  /// **'Primera Bola'**
  String get firstBall;

  /// No description provided for @secondBall.
  ///
  /// In es, this message translates to:
  /// **'Segunda Bola'**
  String get secondBall;

  /// No description provided for @filterByType.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por Tipo'**
  String get filterByType;

  /// No description provided for @filterByDate.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por Fecha'**
  String get filterByDate;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get all;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos disponibles'**
  String get noData;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @darkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Oscuro'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Claro'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Sistema'**
  String get systemMode;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get english;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get signIn;

  /// No description provided for @sync.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar'**
  String get sync;

  /// No description provided for @syncData.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar Datos'**
  String get syncData;

  /// No description provided for @lastSync.
  ///
  /// In es, this message translates to:
  /// **'Última Sincronización'**
  String get lastSync;

  /// No description provided for @userName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de Usuario'**
  String get userName;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo Electrónico'**
  String get email;

  /// No description provided for @club.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get club;

  /// No description provided for @dominantHand.
  ///
  /// In es, this message translates to:
  /// **'Mano Dominante'**
  String get dominantHand;

  /// No description provided for @birthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Nacimiento'**
  String get birthDate;

  /// No description provided for @bio.
  ///
  /// In es, this message translates to:
  /// **'Biografía'**
  String get bio;

  /// No description provided for @avatar.
  ///
  /// In es, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @changeAvatar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Avatar'**
  String get changeAvatar;

  /// No description provided for @fromGallery.
  ///
  /// In es, this message translates to:
  /// **'Desde Galería'**
  String get fromGallery;

  /// No description provided for @fromCamera.
  ///
  /// In es, this message translates to:
  /// **'Desde Cámara'**
  String get fromCamera;

  /// No description provided for @right.
  ///
  /// In es, this message translates to:
  /// **'Derecha'**
  String get right;

  /// No description provided for @left.
  ///
  /// In es, this message translates to:
  /// **'Izquierda'**
  String get left;

  /// No description provided for @deleteConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar esto?'**
  String get deleteConfirmation;

  /// No description provided for @yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @share.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get share;

  /// No description provided for @export.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get export;

  /// No description provided for @import.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get import;

  /// No description provided for @backup.
  ///
  /// In es, this message translates to:
  /// **'Respaldo'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get restore;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get version;

  /// No description provided for @about.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get about;

  /// No description provided for @privacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In es, this message translates to:
  /// **'Términos de Servicio'**
  String get termsOfService;

  /// No description provided for @contact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get contact;

  /// No description provided for @help.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get help;

  /// No description provided for @tutorial.
  ///
  /// In es, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @reportBug.
  ///
  /// In es, this message translates to:
  /// **'Reportar Error'**
  String get reportBug;

  /// No description provided for @rateApp.
  ///
  /// In es, this message translates to:
  /// **'Calificar App'**
  String get rateApp;

  /// No description provided for @streakStrikes.
  ///
  /// In es, this message translates to:
  /// **'Racha de Strikes'**
  String get streakStrikes;

  /// No description provided for @streakSpares.
  ///
  /// In es, this message translates to:
  /// **'Racha de Spares'**
  String get streakSpares;

  /// No description provided for @distribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución'**
  String get distribution;

  /// No description provided for @movingAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio Móvil'**
  String get movingAverage;

  /// No description provided for @heatmap.
  ///
  /// In es, this message translates to:
  /// **'Mapa de Calor'**
  String get heatmap;

  /// No description provided for @topGames.
  ///
  /// In es, this message translates to:
  /// **'Mejores Partidas'**
  String get topGames;

  /// No description provided for @recentGames.
  ///
  /// In es, this message translates to:
  /// **'Partidas Recientes'**
  String get recentGames;

  /// No description provided for @evolution.
  ///
  /// In es, this message translates to:
  /// **'Evolución'**
  String get evolution;

  /// No description provided for @performance.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento'**
  String get performance;

  /// No description provided for @selectDate.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get selectDate;

  /// No description provided for @selectRange.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Rango'**
  String get selectRange;

  /// No description provided for @fromDate.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get toDate;

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get reset;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In es, this message translates to:
  /// **'Filtrar'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In es, this message translates to:
  /// **'Ordenar'**
  String get sort;

  /// No description provided for @ascending.
  ///
  /// In es, this message translates to:
  /// **'Ascendente'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In es, this message translates to:
  /// **'Descendente'**
  String get descending;

  /// No description provided for @byDate.
  ///
  /// In es, this message translates to:
  /// **'Por Fecha'**
  String get byDate;

  /// No description provided for @byScore.
  ///
  /// In es, this message translates to:
  /// **'Por Puntuación'**
  String get byScore;

  /// No description provided for @viewDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver Detalles'**
  String get viewDetails;

  /// No description provided for @editGame.
  ///
  /// In es, this message translates to:
  /// **'Editar Partida'**
  String get editGame;

  /// No description provided for @deleteGame.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Partida'**
  String get deleteGame;

  /// No description provided for @gameDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles de la Partida'**
  String get gameDetails;

  /// No description provided for @sessionDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles de la Sesión'**
  String get sessionDetails;

  /// No description provided for @addNote.
  ///
  /// In es, this message translates to:
  /// **'Agregar Nota'**
  String get addNote;

  /// No description provided for @updateNote.
  ///
  /// In es, this message translates to:
  /// **'Actualizar Nota'**
  String get updateNote;

  /// No description provided for @noSessions.
  ///
  /// In es, this message translates to:
  /// **'No hay sesiones registradas'**
  String get noSessions;

  /// No description provided for @noGames.
  ///
  /// In es, this message translates to:
  /// **'No hay partidas registradas'**
  String get noGames;

  /// No description provided for @createFirstSession.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera sesión'**
  String get createFirstSession;

  /// No description provided for @createFirstGame.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera partida'**
  String get createFirstGame;

  /// No description provided for @loginRequired.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión requerido'**
  String get loginRequired;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para usar esta función'**
  String get loginRequiredMessage;

  /// No description provided for @syncSuccess.
  ///
  /// In es, this message translates to:
  /// **'Datos sincronizados correctamente'**
  String get syncSuccess;

  /// No description provided for @syncError.
  ///
  /// In es, this message translates to:
  /// **'Error al sincronizar datos'**
  String get syncError;

  /// No description provided for @saveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Guardado correctamente'**
  String get saveSuccess;

  /// No description provided for @saveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar'**
  String get saveError;

  /// No description provided for @deleteSuccess.
  ///
  /// In es, this message translates to:
  /// **'Eliminado correctamente'**
  String get deleteSuccess;

  /// No description provided for @deleteError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar'**
  String get deleteError;

  /// No description provided for @updateSuccess.
  ///
  /// In es, this message translates to:
  /// **'Actualizado correctamente'**
  String get updateSuccess;

  /// No description provided for @updateError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar'**
  String get updateError;

  /// No description provided for @validationError.
  ///
  /// In es, this message translates to:
  /// **'Error de validación'**
  String get validationError;

  /// No description provided for @networkError.
  ///
  /// In es, this message translates to:
  /// **'Error de red'**
  String get networkError;

  /// No description provided for @permissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Permiso denegado'**
  String get permissionDenied;

  /// No description provided for @unknownError.
  ///
  /// In es, this message translates to:
  /// **'Error desconocido'**
  String get unknownError;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @fullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullName;

  /// No description provided for @clubName.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get clubName;

  /// No description provided for @hand.
  ///
  /// In es, this message translates to:
  /// **'Mano dominante'**
  String get hand;

  /// No description provided for @rightHand.
  ///
  /// In es, this message translates to:
  /// **'Derecha'**
  String get rightHand;

  /// No description provided for @leftHand.
  ///
  /// In es, this message translates to:
  /// **'Izquierda'**
  String get leftHand;

  /// No description provided for @bothHands.
  ///
  /// In es, this message translates to:
  /// **'Ambas'**
  String get bothHands;

  /// No description provided for @removePhoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get removePhoto;

  /// No description provided for @myProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get myProfile;

  /// No description provided for @saveProfile.
  ///
  /// In es, this message translates to:
  /// **'Guardar perfil'**
  String get saveProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In es, this message translates to:
  /// **'Eliminar perfil'**
  String get deleteProfile;

  /// No description provided for @deleteProfileConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar perfil?'**
  String get deleteProfileConfirmation;

  /// No description provided for @profileSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil guardado correctamente'**
  String get profileSaved;

  /// No description provided for @profileDeleted.
  ///
  /// In es, this message translates to:
  /// **'Perfil eliminado'**
  String get profileDeleted;

  /// No description provided for @profileSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar perfil. Intenta nuevamente.'**
  String get profileSaveError;

  /// No description provided for @profileDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar perfil. Intenta nuevamente.'**
  String get profileDeleteError;

  /// No description provided for @profileUnexpectedSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado al guardar perfil'**
  String get profileUnexpectedSaveError;

  /// No description provided for @profileUnexpectedDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado al eliminar perfil'**
  String get profileUnexpectedDeleteError;

  /// No description provided for @fixErrorsBeforeSaving.
  ///
  /// In es, this message translates to:
  /// **'Corrige los errores antes de guardar'**
  String get fixErrorsBeforeSaving;

  /// No description provided for @addGame.
  ///
  /// In es, this message translates to:
  /// **'Añadir partida'**
  String get addGame;

  /// No description provided for @registerMultipleGames.
  ///
  /// In es, this message translates to:
  /// **'Registrar varias partidas'**
  String get registerMultipleGames;

  /// No description provided for @registerSession.
  ///
  /// In es, this message translates to:
  /// **'Registrar sesión'**
  String get registerSession;

  /// No description provided for @registerGame.
  ///
  /// In es, this message translates to:
  /// **'Registrar partida'**
  String get registerGame;

  /// No description provided for @saveGame.
  ///
  /// In es, this message translates to:
  /// **'Guardar Partida'**
  String get saveGame;

  /// No description provided for @editGameTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Partida'**
  String get editGameTitle;

  /// No description provided for @deleteGameTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar partida'**
  String get deleteGameTitle;

  /// No description provided for @deleteGameConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas eliminar esta partida?'**
  String get deleteGameConfirmation;

  /// No description provided for @gameUpdated.
  ///
  /// In es, this message translates to:
  /// **'Partida actualizada'**
  String get gameUpdated;

  /// No description provided for @gameDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Partida eliminada'**
  String get gameDeletedSuccess;

  /// No description provided for @gameUpdateError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar cambios. Intenta nuevamente.'**
  String get gameUpdateError;

  /// No description provided for @gameDeleteErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar partida. Intenta nuevamente.'**
  String get gameDeleteErrorMessage;

  /// No description provided for @gameUnexpectedUpdateError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado al guardar cambios'**
  String get gameUnexpectedUpdateError;

  /// No description provided for @gameUnexpectedDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado al eliminar partida'**
  String get gameUnexpectedDeleteError;

  /// No description provided for @gameErrors.
  ///
  /// In es, this message translates to:
  /// **'Errores en la partida'**
  String get gameErrors;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @gameInvalidScore.
  ///
  /// In es, this message translates to:
  /// **'La partida no tiene puntuación válida.'**
  String get gameInvalidScore;

  /// No description provided for @addAtLeastOneGame.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos una partida para guardar la sesión.'**
  String get addAtLeastOneGame;

  /// No description provided for @sessionSavedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Sesión guardada correctamente'**
  String get sessionSavedSuccess;

  /// No description provided for @sessionSaveErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar la sesión'**
  String get sessionSaveErrorMessage;

  /// No description provided for @sessionListTitle.
  ///
  /// In es, this message translates to:
  /// **'Sesiones guardadas'**
  String get sessionListTitle;

  /// No description provided for @sessionsList.
  ///
  /// In es, this message translates to:
  /// **'Listado de sesiones registradas'**
  String get sessionsList;

  /// No description provided for @sessionLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar sesiones'**
  String get sessionLoadError;

  /// No description provided for @sessionDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Sesión eliminada'**
  String get sessionDeletedSuccess;

  /// No description provided for @sessionDeleteErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar sesión'**
  String get sessionDeleteErrorMessage;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar sesión'**
  String get deleteSessionTitle;

  /// No description provided for @sessionNotFoundError.
  ///
  /// In es, this message translates to:
  /// **'Error: sesión no encontrada'**
  String get sessionNotFoundError;

  /// No description provided for @fullStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas completas'**
  String get fullStatistics;

  /// No description provided for @performanceSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de tu rendimiento'**
  String get performanceSummary;

  /// No description provided for @viewSessions.
  ///
  /// In es, this message translates to:
  /// **'Ver sesiones'**
  String get viewSessions;

  /// No description provided for @editMyProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar mi perfil'**
  String get editMyProfile;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @deleteProfileMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres borrar tu perfil?\nEsta acción no se puede deshacer.'**
  String get deleteProfileMessage;

  /// No description provided for @signedIn.
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada'**
  String get signedIn;

  /// No description provided for @signOutConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión? Tus datos locales se mantendrán.'**
  String get signOutConfirmation;

  /// No description provided for @moreOptionsComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Más opciones próximamente...'**
  String get moreOptionsComingSoon;

  /// Mensaje de bienvenida con nombre del usuario
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenid@, {name}!'**
  String welcomeUser(String name);

  /// No description provided for @welcomeCreateProfile.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenid@! Antes de nada, crea tu perfil para empezar'**
  String get welcomeCreateProfile;

  /// Etiqueta de club
  ///
  /// In es, this message translates to:
  /// **'Club: {club}'**
  String clubLabel(String club);

  /// Etiqueta de mano dominante
  ///
  /// In es, this message translates to:
  /// **'Mano dominante: {hand}'**
  String dominantHandLabel(String hand);

  /// No description provided for @createMyProfile.
  ///
  /// In es, this message translates to:
  /// **'Crear mi perfil'**
  String get createMyProfile;

  /// No description provided for @profileFromGoogle.
  ///
  /// In es, this message translates to:
  /// **'Perfil creado desde tu cuenta de Google. Puedes editarlo libremente.'**
  String get profileFromGoogle;

  /// No description provided for @imageNotFound.
  ///
  /// In es, this message translates to:
  /// **'Imagen no encontrada, selecciona otra.'**
  String get imageNotFound;

  /// No description provided for @usingGooglePhoto.
  ///
  /// In es, this message translates to:
  /// **'Usando foto de Google. Pulsa para cambiar'**
  String get usingGooglePhoto;

  /// No description provided for @tapToChangeImage.
  ///
  /// In es, this message translates to:
  /// **'Pulsa para cambiar tu imagen'**
  String get tapToChangeImage;

  /// No description provided for @enterYourName.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu nombre'**
  String get enterYourName;

  /// No description provided for @enterValidEmail.
  ///
  /// In es, this message translates to:
  /// **'Introduce un email válido'**
  String get enterValidEmail;

  /// No description provided for @aboutMe.
  ///
  /// In es, this message translates to:
  /// **'Sobre mí'**
  String get aboutMe;

  /// No description provided for @deleteSessionConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas eliminar esta sesión?'**
  String get deleteSessionConfirmation;

  /// No description provided for @syncing.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando...'**
  String get syncing;

  /// No description provided for @saveDataToCloud.
  ///
  /// In es, this message translates to:
  /// **'Guardar datos en la nube'**
  String get saveDataToCloud;

  /// No description provided for @noDataForStatistics.
  ///
  /// In es, this message translates to:
  /// **'No hay datos para mostrar estadísticas.'**
  String get noDataForStatistics;

  /// No description provided for @filter.
  ///
  /// In es, this message translates to:
  /// **'Filtrar:'**
  String get filter;

  /// No description provided for @quickScoreSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen rápido de tus puntuaciones'**
  String get quickScoreSummary;

  /// No description provided for @averageLast5.
  ///
  /// In es, this message translates to:
  /// **'Prom. Últ. 5'**
  String get averageLast5;

  /// No description provided for @best.
  ///
  /// In es, this message translates to:
  /// **'Mejor'**
  String get best;

  /// No description provided for @worst.
  ///
  /// In es, this message translates to:
  /// **'Peor'**
  String get worst;

  /// No description provided for @longestStreakDescription.
  ///
  /// In es, this message translates to:
  /// **'Mayor número de strikes y spares consecutivos en todas tus partidas.'**
  String get longestStreakDescription;

  /// No description provided for @percentageStrikesSparesMisses.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje de Strikes, Spares y Fallos'**
  String get percentageStrikesSparesMisses;

  /// No description provided for @recentEvolution.
  ///
  /// In es, this message translates to:
  /// **'Evolución reciente (media móvil de tus últimas 5 partidas)'**
  String get recentEvolution;

  /// No description provided for @scoreDistribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución de puntuaciones'**
  String get scoreDistribution;

  /// No description provided for @gamesGroupedByRange.
  ///
  /// In es, this message translates to:
  /// **'Número de partidas agrupadas por rango de puntuación'**
  String get gamesGroupedByRange;

  /// No description provided for @topBestWorstGames.
  ///
  /// In es, this message translates to:
  /// **'Tus 3 mejores y peores partidas individuales registradas'**
  String get topBestWorstGames;

  /// No description provided for @top3BestGames.
  ///
  /// In es, this message translates to:
  /// **'Top 3 Mejores Partidas'**
  String get top3BestGames;

  /// No description provided for @top3WorstGames.
  ///
  /// In es, this message translates to:
  /// **'Top 3 Peores Partidas'**
  String get top3WorstGames;

  /// No description provided for @bestWorstSessionDescription.
  ///
  /// In es, this message translates to:
  /// **'Sesión con mejor promedio (récord) y peor sesión'**
  String get bestWorstSessionDescription;

  /// No description provided for @personalRecord.
  ///
  /// In es, this message translates to:
  /// **'¡Récord personal!'**
  String get personalRecord;

  /// No description provided for @worstSession.
  ///
  /// In es, this message translates to:
  /// **'Peor sesión:'**
  String get worstSession;

  /// No description provided for @noSessionsSaved.
  ///
  /// In es, this message translates to:
  /// **'No hay sesiones guardadas.'**
  String get noSessionsSaved;

  /// No description provided for @gamesCount.
  ///
  /// In es, this message translates to:
  /// **'Partidas: {count}'**
  String gamesCount(int count);

  /// No description provided for @noLocation.
  ///
  /// In es, this message translates to:
  /// **'Sin lugar'**
  String get noLocation;

  /// No description provided for @gamesListCount.
  ///
  /// In es, this message translates to:
  /// **'Partidas ({count}):'**
  String gamesListCount(int count);

  /// No description provided for @noGamesRegistered.
  ///
  /// In es, this message translates to:
  /// **'No hay partidas registradas'**
  String get noGamesRegistered;

  /// No description provided for @gameNumber.
  ///
  /// In es, this message translates to:
  /// **'🎳 Partida {number}'**
  String gameNumber(int number);

  /// No description provided for @editTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get editTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteTooltip;

  /// No description provided for @points.
  ///
  /// In es, this message translates to:
  /// **'Puntos: {points}'**
  String points(int points);

  /// No description provided for @gamesWithAverage.
  ///
  /// In es, this message translates to:
  /// **'{count} partidas el {date}. Prom: {average}'**
  String gamesWithAverage(int count, String date, String average);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
