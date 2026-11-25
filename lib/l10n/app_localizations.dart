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

  /// No description provided for @games.
  ///
  /// In es, this message translates to:
  /// **'Partidas'**
  String get games;

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
  /// **'Lugar'**
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

  /// Frames con fallos/abiertos
  ///
  /// In es, this message translates to:
  /// **'Fallos'**
  String get misses;

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

  /// No description provided for @shareSession.
  ///
  /// In es, this message translates to:
  /// **'Compartir sesión'**
  String get shareSession;

  /// No description provided for @shareGame.
  ///
  /// In es, this message translates to:
  /// **'Compartir partida'**
  String get shareGame;

  /// No description provided for @chooseShareFormat.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo quieres compartirlo'**
  String get chooseShareFormat;

  /// No description provided for @shareAsText.
  ///
  /// In es, this message translates to:
  /// **'Como texto'**
  String get shareAsText;

  /// No description provided for @shareAsImage.
  ///
  /// In es, this message translates to:
  /// **'Como imagen'**
  String get shareAsImage;

  /// No description provided for @sessionSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Sesión de bolos'**
  String get sessionSummaryTitle;

  /// No description provided for @gameSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Partida de bolos'**
  String get gameSummaryTitle;

  /// No description provided for @generatedWithApp.
  ///
  /// In es, this message translates to:
  /// **'Generado con Bolómetro'**
  String get generatedWithApp;

  /// No description provided for @shareError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo compartir el resumen. Inténtalo de nuevo.'**
  String get shareError;

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
  /// **'Filtrar:'**
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

  /// No description provided for @uploadToCloudSuccess.
  ///
  /// In es, this message translates to:
  /// **'Datos subidos a la nube correctamente'**
  String get uploadToCloudSuccess;

  /// No description provided for @downloadFromCloudSuccess.
  ///
  /// In es, this message translates to:
  /// **'Datos descargados desde la nube correctamente'**
  String get downloadFromCloudSuccess;

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

  /// No description provided for @gameAdded.
  ///
  /// In es, this message translates to:
  /// **'Partida añadida'**
  String get gameAdded;

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

  /// No description provided for @syncDirection.
  ///
  /// In es, this message translates to:
  /// **'Dirección de sincronización'**
  String get syncDirection;

  /// No description provided for @uploadToCloud.
  ///
  /// In es, this message translates to:
  /// **'Subir a la nube'**
  String get uploadToCloud;

  /// No description provided for @downloadFromCloud.
  ///
  /// In es, this message translates to:
  /// **'Descargar desde la nube'**
  String get downloadFromCloud;

  /// No description provided for @smartSync.
  ///
  /// In es, this message translates to:
  /// **'Sincronización inteligente'**
  String get smartSync;

  /// No description provided for @uploadToCloudDesc.
  ///
  /// In es, this message translates to:
  /// **'Dispositivo → Nube: tus datos locales reemplazarán los de la nube'**
  String get uploadToCloudDesc;

  /// No description provided for @downloadFromCloudDesc.
  ///
  /// In es, this message translates to:
  /// **'Nube → Dispositivo: los datos de la nube reemplazarán los tuyos'**
  String get downloadFromCloudDesc;

  /// No description provided for @smartSyncDesc.
  ///
  /// In es, this message translates to:
  /// **'Combinar datos locales y de la nube'**
  String get smartSyncDesc;

  /// No description provided for @selectSyncDirection.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el tipo de sincronización'**
  String get selectSyncDirection;

  /// No description provided for @noDataForStatistics.
  ///
  /// In es, this message translates to:
  /// **'No hay datos para mostrar estadísticas.'**
  String get noDataForStatistics;

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

  /// Contador de partidas
  ///
  /// In es, this message translates to:
  /// **'Partidas: {count}'**
  String gamesCount(int count);

  /// No description provided for @noLocation.
  ///
  /// In es, this message translates to:
  /// **'Sin lugar'**
  String get noLocation;

  /// Lista de partidas con contador
  ///
  /// In es, this message translates to:
  /// **'Partidas ({count}):'**
  String gamesListCount(int count);

  /// No description provided for @noGamesRegistered.
  ///
  /// In es, this message translates to:
  /// **'No hay partidas registradas'**
  String get noGamesRegistered;

  /// Número de partida
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

  /// Puntos de una partida
  ///
  /// In es, this message translates to:
  /// **'Puntos: {points}'**
  String points(int points);

  /// Descripción de sesión con promedio
  ///
  /// In es, this message translates to:
  /// **'{count} partidas el {date}. Prom: {average}'**
  String gamesWithAverage(int count, String date, String average);

  /// Título de la pantalla de amigos
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get friends;

  /// Pestaña de mis amigos
  ///
  /// In es, this message translates to:
  /// **'Mis Amigos'**
  String get myFriends;

  /// Pestaña de solicitudes de amistad
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get friendRequests;

  /// Botón para añadir un amigo
  ///
  /// In es, this message translates to:
  /// **'Añadir Amigo'**
  String get addFriend;

  /// Descripción de búsqueda de amigos
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código de amigo del usuario'**
  String get searchFriend;

  /// Etiqueta para el código de amigo
  ///
  /// In es, this message translates to:
  /// **'Código de Amigo'**
  String get friendCode;

  /// Etiqueta para mostrar el código de amigo del usuario
  ///
  /// In es, this message translates to:
  /// **'Tu Código de Amigo'**
  String get yourFriendCode;

  /// Botón para copiar código de amigo
  ///
  /// In es, this message translates to:
  /// **'Copiar Código'**
  String get copyFriendCode;

  /// Mensaje al copiar código de amigo
  ///
  /// In es, this message translates to:
  /// **'Código de amigo copiado al portapapeles'**
  String get friendCodeCopied;

  /// Mensaje de validación de código de amigo
  ///
  /// In es, this message translates to:
  /// **'Ingresa un código de amigo'**
  String get enterFriendCode;

  /// Botón para enviar solicitud de amistad
  ///
  /// In es, this message translates to:
  /// **'Enviar Solicitud'**
  String get sendRequest;

  /// Mensaje cuando no se encuentra un usuario
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado'**
  String get userNotFound;

  /// Mensaje de éxito al enviar solicitud
  ///
  /// In es, this message translates to:
  /// **'Solicitud de amistad enviada'**
  String get friendRequestSent;

  /// Mensaje de error al enviar solicitud
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la solicitud'**
  String get couldNotSendRequest;

  /// Mensaje cuando no hay amigos
  ///
  /// In es, this message translates to:
  /// **'No tienes amigos aún'**
  String get noFriendsYet;

  /// Descripción de funcionalidad de amigos
  ///
  /// In es, this message translates to:
  /// **'Añade amigos para comparar tus estadísticas'**
  String get addFriendsToCompare;

  /// Mensaje cuando no hay solicitudes pendientes
  ///
  /// In es, this message translates to:
  /// **'No tienes solicitudes pendientes'**
  String get noPendingRequests;

  /// Mensaje de éxito al aceptar solicitud
  ///
  /// In es, this message translates to:
  /// **'Solicitud aceptada'**
  String get requestAccepted;

  /// Mensaje de éxito al rechazar solicitud
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada'**
  String get requestRejected;

  /// Opción para eliminar un amigo
  ///
  /// In es, this message translates to:
  /// **'Eliminar amigo'**
  String get removeFriend;

  /// Confirmación para eliminar amigo
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar a {name}?'**
  String confirmRemoveFriend(String name);

  /// Mensaje de éxito al eliminar amigo
  ///
  /// In es, this message translates to:
  /// **'Amigo eliminado'**
  String get friendRemoved;

  /// Título de la pantalla de rankings
  ///
  /// In es, this message translates to:
  /// **'Rankings'**
  String get rankings;

  /// Descripción de rankings
  ///
  /// In es, this message translates to:
  /// **'Compárate con tus amigos'**
  String get compareWithFriends;

  /// Filtro de todo el tiempo
  ///
  /// In es, this message translates to:
  /// **'Todo el tiempo'**
  String get allTime;

  /// Filtro de última semana
  ///
  /// In es, this message translates to:
  /// **'Última semana'**
  String get lastWeek;

  /// Filtro de último mes
  ///
  /// In es, this message translates to:
  /// **'Último mes'**
  String get lastMonth;

  /// Filtro de últimos 3 meses
  ///
  /// In es, this message translates to:
  /// **'Últimos 3 meses'**
  String get last3Months;

  /// Mensaje cuando no hay datos de ranking
  ///
  /// In es, this message translates to:
  /// **'No hay datos para mostrar'**
  String get noRankingData;

  /// Descripción de gestión de amigos
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus amigos y solicitudes'**
  String get manageFriends;

  /// Mensaje de validación de email
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico'**
  String get enterEmail;

  /// Indicador de usuario actual
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get you;

  /// Título de la pantalla de logros
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get achievements;

  /// Subtítulo de la pantalla de logros
  ///
  /// In es, this message translates to:
  /// **'Niveles y medallas'**
  String get levelsAndAchievements;

  /// Nivel del usuario
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get level;

  /// Sección de logros desbloqueados
  ///
  /// In es, this message translates to:
  /// **'Logros Desbloqueados'**
  String get unlockedAchievements;

  /// Sección de logros bloqueados
  ///
  /// In es, this message translates to:
  /// **'Logros Bloqueados'**
  String get lockedAchievements;

  /// Rareza común
  ///
  /// In es, this message translates to:
  /// **'Común'**
  String get common;

  /// Rareza rara
  ///
  /// In es, this message translates to:
  /// **'Raro'**
  String get rare;

  /// Rareza épica
  ///
  /// In es, this message translates to:
  /// **'Épico'**
  String get epic;

  /// Rareza legendaria
  ///
  /// In es, this message translates to:
  /// **'Legendario'**
  String get legendary;

  /// Mensaje cuando no hay datos
  ///
  /// In es, this message translates to:
  /// **'No hay datos disponibles'**
  String get noDataAvailable;

  /// Notificación de logro desbloqueado
  ///
  /// In es, this message translates to:
  /// **'¡Logro Desbloqueado!'**
  String get achievementUnlocked;

  /// No description provided for @achievementFirstGameName.
  ///
  /// In es, this message translates to:
  /// **'Primera Partida'**
  String get achievementFirstGameName;

  /// No description provided for @achievementFirstGameDesc.
  ///
  /// In es, this message translates to:
  /// **'Juega tu primera partida'**
  String get achievementFirstGameDesc;

  /// No description provided for @achievementGames10Name.
  ///
  /// In es, this message translates to:
  /// **'Principiante'**
  String get achievementGames10Name;

  /// No description provided for @achievementGames10Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega 10 partidas'**
  String get achievementGames10Desc;

  /// No description provided for @achievementGames50Name.
  ///
  /// In es, this message translates to:
  /// **'Entusiasta'**
  String get achievementGames50Name;

  /// No description provided for @achievementGames50Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega 50 partidas'**
  String get achievementGames50Desc;

  /// No description provided for @achievementGames100Name.
  ///
  /// In es, this message translates to:
  /// **'Veterano'**
  String get achievementGames100Name;

  /// No description provided for @achievementGames100Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega 100 partidas'**
  String get achievementGames100Desc;

  /// No description provided for @achievementStrikes10Name.
  ///
  /// In es, this message translates to:
  /// **'Primeros Strikes'**
  String get achievementStrikes10Name;

  /// No description provided for @achievementStrikes10Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 10 strikes'**
  String get achievementStrikes10Desc;

  /// No description provided for @achievementStrikes50Name.
  ///
  /// In es, this message translates to:
  /// **'Maestro del Strike'**
  String get achievementStrikes50Name;

  /// No description provided for @achievementStrikes50Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 50 strikes'**
  String get achievementStrikes50Desc;

  /// No description provided for @achievementStrikes100Name.
  ///
  /// In es, this message translates to:
  /// **'Leyenda del Strike'**
  String get achievementStrikes100Name;

  /// No description provided for @achievementStrikes100Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 100 strikes'**
  String get achievementStrikes100Desc;

  /// No description provided for @achievementScore150Name.
  ///
  /// In es, this message translates to:
  /// **'Puntuación Alta'**
  String get achievementScore150Name;

  /// No description provided for @achievementScore150Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 150 puntos en una partida'**
  String get achievementScore150Desc;

  /// No description provided for @achievementScore200Name.
  ///
  /// In es, this message translates to:
  /// **'Puntuación Estelar'**
  String get achievementScore200Name;

  /// No description provided for @achievementScore200Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 200 puntos en una partida'**
  String get achievementScore200Desc;

  /// No description provided for @achievementScore250Name.
  ///
  /// In es, this message translates to:
  /// **'Puntuación Legendaria'**
  String get achievementScore250Name;

  /// No description provided for @achievementScore250Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 250 puntos en una partida'**
  String get achievementScore250Desc;

  /// No description provided for @achievementPerfectGameName.
  ///
  /// In es, this message translates to:
  /// **'Partida Perfecta'**
  String get achievementPerfectGameName;

  /// No description provided for @achievementPerfectGameDesc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 300 puntos (partida perfecta)'**
  String get achievementPerfectGameDesc;

  /// No description provided for @achievementStreak3Name.
  ///
  /// In es, this message translates to:
  /// **'Triple Strike'**
  String get achievementStreak3Name;

  /// No description provided for @achievementStreak3Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 3 strikes consecutivos'**
  String get achievementStreak3Desc;

  /// No description provided for @achievementStreak5Name.
  ///
  /// In es, this message translates to:
  /// **'Racha Épica'**
  String get achievementStreak5Name;

  /// No description provided for @achievementStreak5Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 5 strikes consecutivos'**
  String get achievementStreak5Desc;

  /// No description provided for @achievementSpares20Name.
  ///
  /// In es, this message translates to:
  /// **'Experto en Spares'**
  String get achievementSpares20Name;

  /// No description provided for @achievementSpares20Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 20 spares'**
  String get achievementSpares20Desc;

  /// No description provided for @achievementSpares100Name.
  ///
  /// In es, this message translates to:
  /// **'Maestro del Spare'**
  String get achievementSpares100Name;

  /// No description provided for @achievementSpares100Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 100 spares'**
  String get achievementSpares100Desc;

  /// No description provided for @achievementGames250Name.
  ///
  /// In es, this message translates to:
  /// **'Profesional'**
  String get achievementGames250Name;

  /// No description provided for @achievementGames250Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega 250 partidas'**
  String get achievementGames250Desc;

  /// No description provided for @achievementGames500Name.
  ///
  /// In es, this message translates to:
  /// **'Maestro Supremo'**
  String get achievementGames500Name;

  /// No description provided for @achievementGames500Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega 500 partidas'**
  String get achievementGames500Desc;

  /// No description provided for @achievementStrikes250Name.
  ///
  /// In es, this message translates to:
  /// **'Tormenta de Strikes'**
  String get achievementStrikes250Name;

  /// No description provided for @achievementStrikes250Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 250 strikes'**
  String get achievementStrikes250Desc;

  /// No description provided for @achievementStrikes500Name.
  ///
  /// In es, this message translates to:
  /// **'Dios del Strike'**
  String get achievementStrikes500Name;

  /// No description provided for @achievementStrikes500Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 500 strikes'**
  String get achievementStrikes500Desc;

  /// No description provided for @achievementScore275Name.
  ///
  /// In es, this message translates to:
  /// **'Casi Perfecto'**
  String get achievementScore275Name;

  /// No description provided for @achievementScore275Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 275 puntos en una partida'**
  String get achievementScore275Desc;

  /// No description provided for @achievementStreak7Name.
  ///
  /// In es, this message translates to:
  /// **'Racha de Fuego'**
  String get achievementStreak7Name;

  /// No description provided for @achievementStreak7Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 7 strikes consecutivos'**
  String get achievementStreak7Desc;

  /// No description provided for @achievementStreak10Name.
  ///
  /// In es, this message translates to:
  /// **'Racha Imparable'**
  String get achievementStreak10Name;

  /// No description provided for @achievementStreak10Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 10 strikes consecutivos'**
  String get achievementStreak10Desc;

  /// No description provided for @achievementSpares250Name.
  ///
  /// In es, this message translates to:
  /// **'Leyenda del Spare'**
  String get achievementSpares250Name;

  /// No description provided for @achievementSpares250Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 250 spares'**
  String get achievementSpares250Desc;

  /// No description provided for @achievementSpares500Name.
  ///
  /// In es, this message translates to:
  /// **'Dios del Spare'**
  String get achievementSpares500Name;

  /// No description provided for @achievementSpares500Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue 500 spares'**
  String get achievementSpares500Desc;

  /// No description provided for @achievementConsistency5Name.
  ///
  /// In es, this message translates to:
  /// **'Jugador Consistente'**
  String get achievementConsistency5Name;

  /// No description provided for @achievementConsistency5Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega 5 partidas consecutivas con puntuaciones similares (±15 puntos)'**
  String get achievementConsistency5Desc;

  /// No description provided for @achievementConsistency10Name.
  ///
  /// In es, this message translates to:
  /// **'Máquina de Precisión'**
  String get achievementConsistency10Name;

  /// No description provided for @achievementConsistency10Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega 10 partidas consecutivas con puntuaciones similares (±15 puntos)'**
  String get achievementConsistency10Desc;

  /// No description provided for @achievementDedication7Name.
  ///
  /// In es, this message translates to:
  /// **'Semana Activa'**
  String get achievementDedication7Name;

  /// No description provided for @achievementDedication7Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega al menos una vez durante 7 días diferentes'**
  String get achievementDedication7Desc;

  /// No description provided for @achievementDedication30Name.
  ///
  /// In es, this message translates to:
  /// **'Mes Dedicado'**
  String get achievementDedication30Name;

  /// No description provided for @achievementDedication30Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega al menos una vez durante 30 días diferentes'**
  String get achievementDedication30Desc;

  /// No description provided for @achievementDedication100Name.
  ///
  /// In es, this message translates to:
  /// **'Dedicación Legendaria'**
  String get achievementDedication100Name;

  /// No description provided for @achievementDedication100Desc.
  ///
  /// In es, this message translates to:
  /// **'Juega al menos una vez durante 100 días diferentes'**
  String get achievementDedication100Desc;

  /// Opción para restablecer logros y niveles en desarrollo
  ///
  /// In es, this message translates to:
  /// **'Restablecer Progreso (Dev)'**
  String get resetProgress;

  /// Descripción de la opción de restablecer
  ///
  /// In es, this message translates to:
  /// **'Restablecer logros y niveles'**
  String get resetProgressDesc;

  /// Confirmación para restablecer progreso
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas restablecer todos los logros y niveles? Esta acción no se puede deshacer.'**
  String get resetProgressConfirmation;

  /// Mensaje de éxito al restablecer progreso
  ///
  /// In es, this message translates to:
  /// **'Progreso restablecido correctamente'**
  String get resetProgressSuccess;

  /// Mensaje de error al restablecer progreso
  ///
  /// In es, this message translates to:
  /// **'Error al restablecer progreso'**
  String get resetProgressError;

  /// Notificación de solicitud de amistad recibida
  ///
  /// In es, this message translates to:
  /// **'{userName} te ha enviado una solicitud de amistad'**
  String notificationFriendRequest(String userName);

  /// Notificación de solicitud de amistad aceptada
  ///
  /// In es, this message translates to:
  /// **'{userName} aceptó tu solicitud de amistad'**
  String notificationFriendRequestAccepted(String userName);

  /// Título para notificación de solicitud de amistad
  ///
  /// In es, this message translates to:
  /// **'Nueva solicitud de amistad'**
  String get notificationFriendRequestTitle;

  /// Título para notificación de solicitud aceptada
  ///
  /// In es, this message translates to:
  /// **'Solicitud aceptada'**
  String get notificationFriendRequestAcceptedTitle;

  /// Etiqueta para selector de categoría de ranking
  ///
  /// In es, this message translates to:
  /// **'Categoría de Ranking'**
  String get rankingCategory;

  /// Categoría de ranking por promedio
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get categoryAverage;

  /// Categoría de ranking por porcentaje de strikes
  ///
  /// In es, this message translates to:
  /// **'% Strikes'**
  String get categoryStrikesPercent;

  /// Categoría de ranking por porcentaje de spares
  ///
  /// In es, this message translates to:
  /// **'% Spares'**
  String get categorySparesPercent;

  /// Categoría de ranking por mejor partida
  ///
  /// In es, this message translates to:
  /// **'Mejor Partida'**
  String get categoryBestGame;

  /// Categoría de ranking por consistencia (menor desviación estándar)
  ///
  /// In es, this message translates to:
  /// **'Consistencia'**
  String get categoryConsistency;

  /// Botón para comparar estadísticas con un amigo
  ///
  /// In es, this message translates to:
  /// **'Comparar con Amigo'**
  String get compareWithFriend;

  /// Título para pantalla de comparación
  ///
  /// In es, this message translates to:
  /// **'Comparación'**
  String get comparison;

  /// Mensaje para seleccionar amigo
  ///
  /// In es, this message translates to:
  /// **'Selecciona un amigo para comparar'**
  String get selectFriendToCompare;

  /// Título de comparación de estadísticas
  ///
  /// In es, this message translates to:
  /// **'Comparación de Estadísticas'**
  String get statisticsComparison;

  /// Título para gráfico de tendencia de puntuaciones
  ///
  /// In es, this message translates to:
  /// **'Tendencia de Puntuaciones'**
  String get scoresTrend;

  /// Mensaje cuando no hay datos de partidas individuales para el gráfico de tendencia
  ///
  /// In es, this message translates to:
  /// **'Gráfico de tendencia disponible solo con datos de partidas individuales'**
  String get trendChartUnavailable;

  /// Separador para comparaciones
  ///
  /// In es, this message translates to:
  /// **'vs'**
  String get vsComparison;

  /// Métrica de consistencia
  ///
  /// In es, this message translates to:
  /// **'Consistencia'**
  String get consistency;

  /// Indicador de que valores menores son mejores
  ///
  /// In es, this message translates to:
  /// **'Menor es mejor'**
  String get lowerIsBetter;

  /// Mensaje cuando se restaura el borrador de la sesión tras matar la app en segundo plano
  ///
  /// In es, this message translates to:
  /// **'Se ha restaurado tu sesión en curso'**
  String get draftRestoredSession;

  /// Mensaje cuando se restaura el borrador de la partida tras matar la app en segundo plano
  ///
  /// In es, this message translates to:
  /// **'Se ha restaurado tu partida en curso'**
  String get draftRestoredGame;

  /// Título de la sección del cuaderno de notas
  ///
  /// In es, this message translates to:
  /// **'Cuaderno de Notas'**
  String get notebook;

  /// Subtítulo para el acceso al cuaderno de notas en el inicio
  ///
  /// In es, this message translates to:
  /// **'Apuntes y observaciones'**
  String get notebookSubtitle;

  /// Botón para crear una nueva nota
  ///
  /// In es, this message translates to:
  /// **'Nueva Nota'**
  String get newNote;

  /// Título al editar una nota existente
  ///
  /// In es, this message translates to:
  /// **'Editar Nota'**
  String get editNote;

  /// Campo título de una nota
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get noteTitle;

  /// Campo contenido de una nota
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get noteContent;

  /// Texto de sugerencia para el campo título de nota
  ///
  /// In es, this message translates to:
  /// **'Ej: Patrón de aceite en Bolera X'**
  String get noteTitleHint;

  /// Texto de sugerencia para el campo contenido de nota
  ///
  /// In es, this message translates to:
  /// **'Escribe tus apuntes aquí...'**
  String get noteContentHint;

  /// Mensaje de validación cuando el título está vacío
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio'**
  String get noteTitleRequired;

  /// Mensaje cuando no hay notas guardadas
  ///
  /// In es, this message translates to:
  /// **'No hay notas todavía'**
  String get noNotes;

  /// Sugerencia cuando no hay notas guardadas
  ///
  /// In es, this message translates to:
  /// **'Pulsa + para añadir tu primera nota'**
  String get noNotesHint;

  /// Placeholder para la búsqueda de notas
  ///
  /// In es, this message translates to:
  /// **'Buscar notas...'**
  String get searchNotes;

  /// Confirmación antes de eliminar una nota
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta nota?'**
  String get deleteNoteConfirm;

  /// Mensaje cuando la nota se guarda correctamente
  ///
  /// In es, this message translates to:
  /// **'Nota guardada'**
  String get noteSaved;

  /// Mensaje cuando la nota se elimina correctamente
  ///
  /// In es, this message translates to:
  /// **'Nota eliminada'**
  String get noteDeleted;

  /// Etiqueta de fecha de modificación
  ///
  /// In es, this message translates to:
  /// **'Modificado'**
  String get modified;

  /// Título de la pantalla de visualización de nota
  ///
  /// In es, this message translates to:
  /// **'Ver Nota'**
  String get viewNote;

  /// Etiqueta de fecha de creación
  ///
  /// In es, this message translates to:
  /// **'Creado'**
  String get created;

  /// Etiqueta del campo categoría de una nota
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get noteCategory;

  /// Texto de sugerencia cuando no hay categoría asignada
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get noteCategoryNone;

  /// Categoría: General
  ///
  /// In es, this message translates to:
  /// **'General'**
  String get noteCategoryGeneral;

  /// Categoría: Patrón de aceite
  ///
  /// In es, this message translates to:
  /// **'Patrón de aceite'**
  String get noteCategoryOil;

  /// Categoría: Técnica
  ///
  /// In es, this message translates to:
  /// **'Técnica'**
  String get noteCategoryTechnique;

  /// Categoría: Equipamiento
  ///
  /// In es, this message translates to:
  /// **'Equipamiento'**
  String get noteCategoryEquipment;

  /// Categoría: Juego Mental
  ///
  /// In es, this message translates to:
  /// **'Juego Mental'**
  String get noteCategoryMental;

  /// Categoría: Bolera
  ///
  /// In es, this message translates to:
  /// **'Bolera'**
  String get noteCategoryAlley;

  /// Etiqueta del campo tipo de nota
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get noteType;

  /// Tipo de nota técnica
  ///
  /// In es, this message translates to:
  /// **'Técnica'**
  String get noteTypeTechnique;

  /// Tipo de nota de pista
  ///
  /// In es, this message translates to:
  /// **'Pista'**
  String get noteTypeLane;

  /// Tipo de nota de aceite
  ///
  /// In es, this message translates to:
  /// **'Aceite'**
  String get noteTypeOil;

  /// Tipo de nota de equipamiento
  ///
  /// In es, this message translates to:
  /// **'Equipamiento'**
  String get noteTypeEquipment;

  /// Tipo de nota mental
  ///
  /// In es, this message translates to:
  /// **'Mental'**
  String get noteTypeMental;

  /// Tipo de nota de review
  ///
  /// In es, this message translates to:
  /// **'Review'**
  String get noteTypeReview;

  /// Etiqueta del campo estado de la nota
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get noteStatus;

  /// Estado pendiente de validar
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get noteStatusPending;

  /// Estado probado
  ///
  /// In es, this message translates to:
  /// **'Probado'**
  String get noteStatusTested;

  /// Estado validado
  ///
  /// In es, this message translates to:
  /// **'Validado'**
  String get noteStatusValidated;

  /// Estado descartado
  ///
  /// In es, this message translates to:
  /// **'Descartado'**
  String get noteStatusDiscarded;

  /// Tooltip para marcar/desmarcar una nota como favorita
  ///
  /// In es, this message translates to:
  /// **'Favorita'**
  String get noteFavorite;

  /// Etiqueta del selector de color de nota
  ///
  /// In es, this message translates to:
  /// **'Color de la nota'**
  String get noteColorLabel;

  /// Título del diálogo de ordenación de notas
  ///
  /// In es, this message translates to:
  /// **'Ordenar notas'**
  String get sortNotes;

  /// Opción de ordenación: más recientes primero
  ///
  /// In es, this message translates to:
  /// **'Más recientes'**
  String get sortNewest;

  /// Opción de ordenación: más antiguas primero
  ///
  /// In es, this message translates to:
  /// **'Más antiguas'**
  String get sortOldest;

  /// Opción de ordenación: por título
  ///
  /// In es, this message translates to:
  /// **'Por título'**
  String get sortByTitle;

  /// Opción de ordenación: favoritas primero
  ///
  /// In es, this message translates to:
  /// **'Favoritas primero'**
  String get sortFavFirst;

  /// Número de palabras en el contenido de la nota
  ///
  /// In es, this message translates to:
  /// **'{count} palabras'**
  String noteWordCount(int count);

  /// Filtro para mostrar todas las notas
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get filterAll;

  /// Etiqueta para sección de plantillas rápidas en edición de notas
  ///
  /// In es, this message translates to:
  /// **'Plantillas rápidas'**
  String get noteTemplates;

  /// Nombre de plantilla rápida para observación de técnica
  ///
  /// In es, this message translates to:
  /// **'Observación de técnica'**
  String get noteTemplateTechnique;

  /// Título por defecto de plantilla de observación de técnica
  ///
  /// In es, this message translates to:
  /// **'Observación de técnica'**
  String get noteTemplateTechniqueTitle;

  /// Contenido por defecto de plantilla de observación de técnica
  ///
  /// In es, this message translates to:
  /// **'Situación:\\nObservación:\\nAjuste:\\nResultado:\\nSiguiente paso:'**
  String get noteTemplateTechniqueContent;

  /// Nombre de plantilla rápida para lectura de pista
  ///
  /// In es, this message translates to:
  /// **'Lectura de pista'**
  String get noteTemplateLaneRead;

  /// Título por defecto de plantilla de lectura de pista
  ///
  /// In es, this message translates to:
  /// **'Lectura de pista y transición'**
  String get noteTemplateLaneReadTitle;

  /// Contenido por defecto de plantilla de lectura de pista
  ///
  /// In es, this message translates to:
  /// **'Línea inicial:\\nTransición observada:\\nReacción de la bola:\\nMovimiento recomendado:'**
  String get noteTemplateLaneReadContent;

  /// Nombre de plantilla rápida para patrón de aceite
  ///
  /// In es, this message translates to:
  /// **'Patrón de aceite'**
  String get noteTemplateOilPattern;

  /// Título por defecto de plantilla de patrón de aceite
  ///
  /// In es, this message translates to:
  /// **'Notas de patrón de aceite'**
  String get noteTemplateOilPatternTitle;

  /// Contenido por defecto de plantilla de patrón de aceite
  ///
  /// In es, this message translates to:
  /// **'Nombre del patrón:\\nLongitud/ratio:\\nTablón de referencia:\\nPlan de ajustes:'**
  String get noteTemplateOilPatternContent;

  /// Nombre de plantilla rápida para ajuste de equipamiento
  ///
  /// In es, this message translates to:
  /// **'Ajuste de equipamiento'**
  String get noteTemplateEquipmentAdjust;

  /// Título por defecto de plantilla de ajuste de equipamiento
  ///
  /// In es, this message translates to:
  /// **'Ajuste de equipamiento'**
  String get noteTemplateEquipmentAdjustTitle;

  /// Contenido por defecto de plantilla de ajuste de equipamiento
  ///
  /// In es, this message translates to:
  /// **'Bola/layout usado:\\nCambio de superficie o mano:\\nCuándo usarlo:\\nResultado observado:'**
  String get noteTemplateEquipmentAdjustContent;

  /// Nombre de plantilla rápida para review post-sesión
  ///
  /// In es, this message translates to:
  /// **'Review post-sesión'**
  String get noteTemplatePostReview;

  /// Título por defecto de plantilla de review post-sesión
  ///
  /// In es, this message translates to:
  /// **'Review post-sesión'**
  String get noteTemplatePostReviewTitle;

  /// Contenido por defecto de plantilla de review post-sesión
  ///
  /// In es, this message translates to:
  /// **'Qué funcionó:\\nQué no funcionó:\\nAprendizaje clave:\\nFoco para la próxima sesión:'**
  String get noteTemplatePostReviewContent;

  /// Etiqueta del campo tags en notas
  ///
  /// In es, this message translates to:
  /// **'Tags'**
  String get noteTags;

  /// Texto de ayuda para el campo tags en notas
  ///
  /// In es, this message translates to:
  /// **'Ejemplo: spare, timing, pista seca'**
  String get noteTagsHint;

  /// Título de sección para metadatos contextuales de la nota
  ///
  /// In es, this message translates to:
  /// **'Contexto'**
  String get noteContext;

  /// Etiqueta del campo bolera
  ///
  /// In es, this message translates to:
  /// **'Bolera'**
  String get noteBowlingAlley;

  /// Etiqueta del campo patrón de aceite
  ///
  /// In es, this message translates to:
  /// **'Patrón de aceite'**
  String get noteOilPattern;

  /// Etiqueta del campo bola usada o equipamiento
  ///
  /// In es, this message translates to:
  /// **'Bola / equipamiento'**
  String get noteBallOrEquipment;

  /// Etiqueta del campo condición de pista
  ///
  /// In es, this message translates to:
  /// **'Condición de pista'**
  String get noteLaneCondition;

  /// Etiqueta para seleccionar sesión relacionada en nota
  ///
  /// In es, this message translates to:
  /// **'Sesión relacionada'**
  String get noteRelatedSession;

  /// Opción para no vincular una sesión en la nota
  ///
  /// In es, this message translates to:
  /// **'Sin sesión vinculada'**
  String get noteNoLinkedSession;

  /// Texto fallback cuando no se encuentra la sesión vinculada
  ///
  /// In es, this message translates to:
  /// **'Sesión vinculada (no disponible localmente)'**
  String get noteLinkedSessionUnknown;

  /// Etiqueta de estado archivado de una nota
  ///
  /// In es, this message translates to:
  /// **'Archivada'**
  String get noteArchived;

  /// Texto de ayuda para toggle de archivado en nota
  ///
  /// In es, this message translates to:
  /// **'Archiva esta nota para ocultarla del listado activo'**
  String get noteArchivedHint;

  /// Acción para fijar una nota
  ///
  /// In es, this message translates to:
  /// **'Fijar'**
  String get notePin;

  /// Acción para desfijar una nota
  ///
  /// In es, this message translates to:
  /// **'Desfijar'**
  String get noteUnpin;

  /// Etiqueta de estado fijada de una nota
  ///
  /// In es, this message translates to:
  /// **'Fijada'**
  String get notePinned;

  /// Acción para archivar una nota
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get noteArchive;

  /// Acción para desarchivar una nota
  ///
  /// In es, this message translates to:
  /// **'Desarchivar'**
  String get noteUnarchive;

  /// Filtro para mostrar notas activas
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get noteFilterActive;

  /// Filtro para mostrar notas archivadas
  ///
  /// In es, this message translates to:
  /// **'Archivadas'**
  String get noteFilterArchived;

  /// Filtro para quitar filtro por categoría en notas
  ///
  /// In es, this message translates to:
  /// **'Todas las categorías'**
  String get noteFilterAllCategories;

  /// Filtro para quitar filtro por tags en notas
  ///
  /// In es, this message translates to:
  /// **'Todos los tags'**
  String get noteFilterAllTags;

  /// Filtro para quitar filtro por tipo en notas
  ///
  /// In es, this message translates to:
  /// **'Todos los tipos'**
  String get noteFilterAllTypes;

  /// Filtro para quitar filtro por estado en notas
  ///
  /// In es, this message translates to:
  /// **'Todos los estados'**
  String get noteFilterAllStatuses;

  /// Etiqueta del botón para abrir el panel de filtros avanzados
  ///
  /// In es, this message translates to:
  /// **'Filtros avanzados'**
  String get noteAdvancedFilters;

  /// Etiqueta del botón para restablecer todos los filtros de notas
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get noteResetFilters;

  /// Título de la sección de resumen/insights en el panel de filtros
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get noteSummary;

  /// Título de la sección de orden en el panel de filtros
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get noteSortOrder;

  /// Mensaje de apoyo para destacar notas pendientes de validación
  ///
  /// In es, this message translates to:
  /// **'Notas pendientes o por validar para revisar antes de la próxima sesión'**
  String get notesPendingValidation;

  /// Contador de notas pendientes de validar
  ///
  /// In es, this message translates to:
  /// **'{count} notas por validar'**
  String notesPendingValidationCount(int count);

  /// Título de sección de notas relacionadas con la sesión
  ///
  /// In es, this message translates to:
  /// **'Notas relacionadas ({count})'**
  String sessionRelatedNotes(int count);

  /// Mensaje cuando la sesión no tiene notas relacionadas
  ///
  /// In es, this message translates to:
  /// **'No hay notas vinculadas a esta sesión'**
  String get sessionNoRelatedNotes;

  /// Etiqueta del botón para crear nota desde plantilla rápida
  ///
  /// In es, this message translates to:
  /// **'Crear desde plantilla'**
  String get noteCreateFromTemplate;

  /// Título del diálogo de confirmación para descartar cambios
  ///
  /// In es, this message translates to:
  /// **'Descartar cambios'**
  String get discardChanges;

  /// Mensaje mostrado cuando el usuario intenta salir con datos sin guardar
  ///
  /// In es, this message translates to:
  /// **'Tienes datos sin guardar. ¿Quieres salir sin guardar?'**
  String get discardChangesMessage;

  /// Etiqueta del botón para confirmar el descarte de cambios
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// Título de la sección de estadísticas generales
  ///
  /// In es, this message translates to:
  /// **'Estadísticas Generales'**
  String get statsGeneralSection;

  /// Título de la sección de evolución y distribución de puntuaciones
  ///
  /// In es, this message translates to:
  /// **'Evolución y Distribución'**
  String get statsEvolutionSection;

  /// Título de la sección de mejores y peores partidas y sesiones
  ///
  /// In es, this message translates to:
  /// **'Mejores y Peores'**
  String get statsBestWorstSection;

  /// Título de la sección de estadísticas basadas en datos de pines
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Pines'**
  String get pinStatsSection;

  /// Nota indicando que las estadísticas de pines requieren el teclado visual
  ///
  /// In es, this message translates to:
  /// **'Disponible solo para partidas registradas con el teclado de pines'**
  String get pinStatsNote;

  /// Etiqueta para el promedio de pinos en el primer tiro
  ///
  /// In es, this message translates to:
  /// **'Prom. 1ª Bola'**
  String get firstBallAvg;

  /// Etiqueta para la tasa de conversión de spare
  ///
  /// In es, this message translates to:
  /// **'Conv. Spare'**
  String get spareConversionRate;

  /// Título de la sección de conversión de spare desglosada por pin
  ///
  /// In es, this message translates to:
  /// **'Remate por Pin'**
  String get perPinSpareStats;

  /// Etiqueta que muestra el remate (pines a derribar en el segundo tiro)
  ///
  /// In es, this message translates to:
  /// **'Remate: {pins}'**
  String perPinLeaveLabel(String pins);

  /// Muestra las conversiones sobre las oportunidades para un deje
  ///
  /// In es, this message translates to:
  /// **'{converted}/{attempts}'**
  String perPinConversionValue(int converted, int attempts);

  /// Subtítulo de la pantalla de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Registra y analiza tus partidas de bolos'**
  String get loginSubtitle;

  /// Título de la sección de beneficios de iniciar sesión
  ///
  /// In es, this message translates to:
  /// **'¿Por qué iniciar sesión?'**
  String get whySignIn;

  /// Beneficio de sincronización entre dispositivos
  ///
  /// In es, this message translates to:
  /// **'Sincroniza tus datos en todos tus dispositivos'**
  String get syncDevices;

  /// Beneficio de copia de seguridad automática
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad automática en la nube'**
  String get autoBackup;

  /// Beneficio de funciones sociales futuras
  ///
  /// In es, this message translates to:
  /// **'Prepárate para funciones sociales futuras'**
  String get socialFeatures;

  /// Texto mostrado mientras se inicia sesión
  ///
  /// In es, this message translates to:
  /// **'Iniciando sesión...'**
  String get signingIn;

  /// Nota de privacidad en la pantalla de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Tus datos personales están seguros. Solo accedemos a tu información básica de perfil.'**
  String get privacyNote;

  /// Tiempo transcurrido en días (plural)
  ///
  /// In es, this message translates to:
  /// **'Hace {count} días'**
  String timeAgoDays(int count);

  /// Tiempo transcurrido de exactamente 1 día
  ///
  /// In es, this message translates to:
  /// **'Hace 1 día'**
  String get timeAgoDay;

  /// Tiempo transcurrido en horas (plural)
  ///
  /// In es, this message translates to:
  /// **'Hace {count} horas'**
  String timeAgoHours(int count);

  /// Tiempo transcurrido de exactamente 1 hora
  ///
  /// In es, this message translates to:
  /// **'Hace 1 hora'**
  String get timeAgoHour;

  /// Tiempo transcurrido en minutos (plural)
  ///
  /// In es, this message translates to:
  /// **'Hace {count} minutos'**
  String timeAgoMinutes(int count);

  /// Tiempo transcurrido de exactamente 1 minuto
  ///
  /// In es, this message translates to:
  /// **'Hace 1 minuto'**
  String get timeAgoMinute;

  /// Tiempo transcurrido menor a un minuto
  ///
  /// In es, this message translates to:
  /// **'Hace menos de un minuto'**
  String get timeAgoJustNow;

  /// Botón para cambiar al modo de teclado clásico en el registro de partida
  ///
  /// In es, this message translates to:
  /// **'Cambiar a teclado clásico'**
  String get switchToClassicKeyboard;

  /// Botón para cambiar al modo visual de registro de pines
  ///
  /// In es, this message translates to:
  /// **'Registrar bolos visualmente'**
  String get registerPinsVisually;

  /// Etiqueta del selector de tipo de sesión (entrenamiento/competición)
  ///
  /// In es, this message translates to:
  /// **'Tipo de sesión'**
  String get sessionType;

  /// Mensaje cuando no hay partidas añadidas en la lista
  ///
  /// In es, this message translates to:
  /// **'No hay partidas añadidas'**
  String get noGamesAdded;

  /// Leyenda del mapa de calor para 1 partida
  ///
  /// In es, this message translates to:
  /// **'1 partida'**
  String get heatmap1Game;

  /// Leyenda del mapa de calor para 3 o más partidas
  ///
  /// In es, this message translates to:
  /// **'3+ partidas'**
  String get heatmap3Games;

  /// Leyenda del mapa de calor para 5 o más partidas
  ///
  /// In es, this message translates to:
  /// **'5+ partidas'**
  String get heatmap5Games;

  /// Mensaje cuando no hay partidas para exportar
  ///
  /// In es, this message translates to:
  /// **'No hay partidas para exportar'**
  String get noGamesToExport;

  /// Mensaje de confirmación al exportar partidas
  ///
  /// In es, this message translates to:
  /// **'Exportación completada'**
  String get exportSuccess;

  /// Texto para compartir al exportar partidas
  ///
  /// In es, this message translates to:
  /// **'Mis partidas de bolos'**
  String get exportShareText;

  /// Mensaje de error al acceder a las partidas para exportar
  ///
  /// In es, this message translates to:
  /// **'Error al acceder a las partidas. Intenta nuevamente.'**
  String get exportErrorAccess;

  /// Mensaje de error general al exportar partidas
  ///
  /// In es, this message translates to:
  /// **'Error al exportar partidas. Intenta nuevamente.'**
  String get exportErrorGeneral;

  /// Botón para marcar un strike en el teclado de pines
  ///
  /// In es, this message translates to:
  /// **'Pleno'**
  String get strike;

  /// Botón para marcar un semipleno (derribar todos los pines disponibles) en la tercera tirada del décimo frame
  ///
  /// In es, this message translates to:
  /// **'Semipleno'**
  String get semipleno;

  /// Botón para marcar un spare en el teclado de pines
  ///
  /// In es, this message translates to:
  /// **'Remate'**
  String get spare;

  /// Botón para marcar un fallo en el teclado de pines
  ///
  /// In es, this message translates to:
  /// **'Fallo'**
  String get miss;

  /// Botón para confirmar la selección de pines
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// Mensaje de motivación cuando el jugador tiene una buena racha
  ///
  /// In es, this message translates to:
  /// **'¡Vas en racha!'**
  String get onStreak;

  /// Etiqueta de la sección de detalle de pines por tiro en la vista de partida
  ///
  /// In es, this message translates to:
  /// **'Pines por tiro'**
  String get pinsPerThrow;

  /// Botón para continuar la autenticación usando correo electrónico y contraseña
  ///
  /// In es, this message translates to:
  /// **'Continuar con correo electrónico'**
  String get continueWithEmail;

  /// Mensaje de confirmación tras enviar un correo de recuperación de contraseña
  ///
  /// In es, this message translates to:
  /// **'Correo de recuperación enviado'**
  String get passwordResetSent;

  /// Botón/título para crear una nueva cuenta
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get createAccount;

  /// Etiqueta del campo de contraseña
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// Mensaje de validación que pide al usuario introducir una contraseña
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get enterPassword;

  /// Mensaje de validación cuando la contraseña es demasiado corta
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get passwordTooShort;

  /// Mensaje de validación cuando los dos campos de contraseña no coinciden
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordsDoNotMatch;

  /// Enlace para iniciar el flujo de recuperación de contraseña
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// Enlace mostrado en el modo de registro para cambiar al modo de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get alreadyHaveAccount;

  /// Enlace mostrado en el modo de inicio de sesión para cambiar al modo de registro
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get noAccount;

  /// Título del diálogo de actualización
  ///
  /// In es, this message translates to:
  /// **'¡Nueva versión disponible!'**
  String get updateAvailable;

  /// Etiqueta que precede al número de la nueva versión
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get updateVersion;

  /// Encabezado de la lista de cambios de la nueva versión
  ///
  /// In es, this message translates to:
  /// **'Novedades'**
  String get updateChangelog;

  /// Botón para ir a la tienda y actualizar la app
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get updateNow;

  /// Botón para posponer la actualización
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get updateLater;

  /// Mensaje de error cuando no se puede abrir la URL de la tienda
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la tienda de aplicaciones'**
  String get updateOpenStoreFailed;

  /// Etiqueta para el filtro de rango de fechas en estadísticas
  ///
  /// In es, this message translates to:
  /// **'Período'**
  String get filterDateRange;

  /// Etiqueta para el filtro de últimas N partidas en estadísticas
  ///
  /// In es, this message translates to:
  /// **'Partidas'**
  String get filterLastNGames;

  /// Preset de rango de fechas: últimos 7 días
  ///
  /// In es, this message translates to:
  /// **'Últ. 7 días'**
  String get datePresetLast7Days;

  /// Preset de rango de fechas: últimos 30 días
  ///
  /// In es, this message translates to:
  /// **'Últ. 30 días'**
  String get datePresetLast30Days;

  /// Preset de rango de fechas: últimos 90 días
  ///
  /// In es, this message translates to:
  /// **'Últ. 90 días'**
  String get datePresetLast90Days;

  /// Preset de rango de fechas: este mes
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get datePresetThisMonth;

  /// Preset de rango de fechas: este año
  ///
  /// In es, this message translates to:
  /// **'Este año'**
  String get datePresetThisYear;

  /// Preset de rango de fechas: todo el tiempo
  ///
  /// In es, this message translates to:
  /// **'Siempre'**
  String get datePresetAllTime;

  /// Preset de rango de fechas: rango personalizado
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get datePresetCustom;

  /// Opción del filtro últimas N partidas: todas las partidas
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get lastNAll;

  /// Opción del filtro últimas N partidas: últimas 10
  ///
  /// In es, this message translates to:
  /// **'Últ. 10'**
  String get lastN10;

  /// Opción del filtro últimas N partidas: últimas 25
  ///
  /// In es, this message translates to:
  /// **'Últ. 25'**
  String get lastN25;

  /// Opción del filtro últimas N partidas: últimas 50
  ///
  /// In es, this message translates to:
  /// **'Últ. 50'**
  String get lastN50;

  /// Título del selector de rango de fechas personalizado
  ///
  /// In es, this message translates to:
  /// **'Seleccionar rango de fechas'**
  String get selectDateRange;

  /// Texto de ayuda para el gráfico de promedio móvil
  ///
  /// In es, this message translates to:
  /// **'Promedio móvil calculado sobre las últimas 5 partidas. Suaviza las variaciones individuales.'**
  String get tooltipMovingAverage;

  /// Texto de ayuda para el histograma de puntuaciones
  ///
  /// In es, this message translates to:
  /// **'Distribución de tus puntuaciones en rangos de 20 puntos.'**
  String get tooltipHistogram;

  /// Texto de ayuda para la tasa de conversión de spare
  ///
  /// In es, this message translates to:
  /// **'Porcentaje de veces que convertiste el spare cuando tuviste la oportunidad.'**
  String get tooltipSpareConversion;

  /// Texto de ayuda para el promedio de primera bola
  ///
  /// In es, this message translates to:
  /// **'Promedio de pinos derribados en el primer tiro de cada frame.'**
  String get tooltipFirstBall;

  /// Etiqueta del KPI de promedio en el header fijo
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get stickyKpiAverage;

  /// Etiqueta del KPI de mejor puntuación en el header fijo
  ///
  /// In es, this message translates to:
  /// **'Mejor'**
  String get stickyKpiBest;

  /// Etiqueta del KPI de peor puntuación en el header fijo
  ///
  /// In es, this message translates to:
  /// **'Peor'**
  String get stickyKpiWorst;

  /// Etiqueta del KPI de total de partidas en el header fijo
  ///
  /// In es, this message translates to:
  /// **'Partidas'**
  String get stickyKpiGames;

  /// Acción para abrir el formulario de feedback in-app
  ///
  /// In es, this message translates to:
  /// **'Enviar feedback'**
  String get sendFeedback;

  /// Etiqueta para el selector de tipo de feedback
  ///
  /// In es, this message translates to:
  /// **'Tipo de feedback'**
  String get feedbackTypeLabel;

  /// Opción de tipo de feedback para sugerencias
  ///
  /// In es, this message translates to:
  /// **'Sugerencia'**
  String get feedbackTypeSuggestion;

  /// Opción de tipo de feedback para reportes de errores
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get feedbackTypeBug;

  /// Opción de tipo para feedback sin categoría
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get feedbackTypeOther;

  /// Etiqueta del campo de mensaje de feedback
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get feedbackMessageLabel;

  /// Texto de ayuda para el campo de mensaje
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué ha pasado o qué podemos mejorar'**
  String get feedbackMessageHint;

  /// Error de validación cuando el mensaje está vacío
  ///
  /// In es, this message translates to:
  /// **'El mensaje es obligatorio'**
  String get feedbackMessageRequired;

  /// Etiqueta del campo de correo opcional de feedback
  ///
  /// In es, this message translates to:
  /// **'Correo de contacto (opcional)'**
  String get feedbackEmailLabel;

  /// Texto de ayuda para el correo opcional
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get feedbackEmailHint;

  /// Error de validación de formato de correo
  ///
  /// In es, this message translates to:
  /// **'Introduce un correo válido'**
  String get feedbackInvalidEmail;

  /// Etiqueta para la valoración opcional del feedback
  ///
  /// In es, this message translates to:
  /// **'Valoración'**
  String get feedbackRatingLabel;

  /// Texto de opción cuando no hay valoración
  ///
  /// In es, this message translates to:
  /// **'Sin valoración'**
  String get feedbackRatingOptional;

  /// Texto del botón para enviar feedback
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get feedbackSubmit;

  /// Texto de carga mientras se envía el feedback
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get feedbackSubmitting;

  /// Mensaje de confirmación tras enviar feedback
  ///
  /// In es, this message translates to:
  /// **'¡Gracias! Tu feedback se ha enviado'**
  String get feedbackSentSuccess;

  /// Prefijo de error cuando falla el envío de feedback
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el feedback'**
  String get feedbackSubmitError;

  /// Label for seasons section
  ///
  /// In es, this message translates to:
  /// **'Temporadas'**
  String get seasons;

  /// Subtitle for the seasons management card on home
  ///
  /// In es, this message translates to:
  /// **'Organiza tus sesiones por temporadas'**
  String get manageSeasonsSubtitle;

  /// Title for the seasons management screen
  ///
  /// In es, this message translates to:
  /// **'Gestión de temporadas'**
  String get seasonsManagement;

  /// Empty state label when no seasons exist
  ///
  /// In es, this message translates to:
  /// **'Aún no hay temporadas'**
  String get noSeasonsYet;

  /// Hint shown below the empty state label
  ///
  /// In es, this message translates to:
  /// **'Pulsa + para crear la primera'**
  String get noSeasonsYetHint;

  /// Label indicating the active/default season
  ///
  /// In es, this message translates to:
  /// **'Temporada activa'**
  String get activeSeason;

  /// Action to set a season as the active default
  ///
  /// In es, this message translates to:
  /// **'Marcar como activa'**
  String get setAsActive;

  /// Action to rename a season
  ///
  /// In es, this message translates to:
  /// **'Renombrar temporada'**
  String get renameSeason;

  /// Action to delete a season
  ///
  /// In es, this message translates to:
  /// **'Eliminar temporada'**
  String get deleteSeason;

  /// Confirmation message before deleting a season
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la temporada \"{name}\"? Las sesiones asociadas no se borrarán.'**
  String deleteSeasonConfirm(String name);

  /// Title of the dialog for creating a new season
  ///
  /// In es, this message translates to:
  /// **'Nueva temporada'**
  String get newSeasonTitle;

  /// Hint text for the season name field
  ///
  /// In es, this message translates to:
  /// **'Ej: 2025-2026'**
  String get newSeasonHint;

  /// Validation error for empty season name
  ///
  /// In es, this message translates to:
  /// **'El nombre no puede estar vacío'**
  String get seasonNameRequired;

  /// Validation error when trying to add a duplicate season name
  ///
  /// In es, this message translates to:
  /// **'Ya existe una temporada con ese nombre'**
  String get seasonAlreadyExists;

  /// Snackbar confirmation when a season is successfully added
  ///
  /// In es, this message translates to:
  /// **'Temporada creada'**
  String get seasonAdded;

  /// Snackbar confirmation when a season is successfully renamed
  ///
  /// In es, this message translates to:
  /// **'Temporada renombrada'**
  String get seasonRenamed;

  /// Snackbar confirmation when a season is deleted
  ///
  /// In es, this message translates to:
  /// **'Temporada eliminada'**
  String get seasonDeleted;

  /// Action to archive a season
  ///
  /// In es, this message translates to:
  /// **'Archivar temporada'**
  String get archiveSeason;

  /// Confirmation message before archiving a season
  ///
  /// In es, this message translates to:
  /// **'¿Archivar la temporada \"{name}\"? Podrás consultarla pero no añadir sesiones.'**
  String archiveSeasonConfirm(String name);

  /// Action to unarchive a season
  ///
  /// In es, this message translates to:
  /// **'Desarchivar temporada'**
  String get unarchiveSeason;

  /// Snackbar confirmation when a season is archived
  ///
  /// In es, this message translates to:
  /// **'Temporada archivada'**
  String get seasonArchived;

  /// Snackbar confirmation when a season is unarchived
  ///
  /// In es, this message translates to:
  /// **'Temporada desarchivada'**
  String get seasonUnarchived;

  /// Section title for archived seasons list
  ///
  /// In es, this message translates to:
  /// **'Temporadas archivadas'**
  String get archivedSeasons;

  /// Badge shown next to archived seasons
  ///
  /// In es, this message translates to:
  /// **'Archivada'**
  String get archivedSeasonLabel;

  /// Button label to show archived seasons
  ///
  /// In es, this message translates to:
  /// **'Mostrar archivadas'**
  String get showArchivedSeasons;

  /// Button label to hide archived seasons
  ///
  /// In es, this message translates to:
  /// **'Ocultar archivadas'**
  String get hideArchivedSeasons;

  /// Number of sessions associated with a season
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 sesión} other{{count} sesiones}}'**
  String sessionCountForSeason(int count);

  /// Label for the special no-season option
  ///
  /// In es, this message translates to:
  /// **'Sin temporada'**
  String get sinTemporada;

  /// Badge shown next to the active/default season
  ///
  /// In es, this message translates to:
  /// **'Predeterminada'**
  String get defaultSeasonLabel;

  /// Label for the season selector in the session registration form
  ///
  /// In es, this message translates to:
  /// **'Temporada'**
  String get selectSeason;

  /// Title for season-focused statistics summary card
  ///
  /// In es, this message translates to:
  /// **'Resumen de la temporada {season}'**
  String seasonFocusTitle(String season);

  /// Heading for previous season comparison inside season stats card
  ///
  /// In es, this message translates to:
  /// **'Comparación con la temporada anterior'**
  String get seasonComparisonSection;

  /// Fallback text when there is no previous season comparison
  ///
  /// In es, this message translates to:
  /// **'No hay temporada anterior disponible para comparar.'**
  String get seasonComparisonUnavailable;

  /// Heading for season record highlights section
  ///
  /// In es, this message translates to:
  /// **'Récords de la temporada'**
  String get seasonRecordsSection;

  /// Label for season best game metric
  ///
  /// In es, this message translates to:
  /// **'Mejor partida'**
  String get seasonBestGameLabel;

  /// Label for season best session metric
  ///
  /// In es, this message translates to:
  /// **'Mejor sesión'**
  String get seasonBestSessionLabel;

  /// Tooltip/acción para seleccionar todas las sesiones filtradas en modo selección múltiple
  ///
  /// In es, this message translates to:
  /// **'Seleccionar todo'**
  String get selectAll;

  /// Tooltip/acción para limpiar la selección múltiple actual
  ///
  /// In es, this message translates to:
  /// **'Deseleccionar todo'**
  String get deselectAll;

  /// Tooltip/acción para entrar en modo de selección múltiple de sesiones
  ///
  /// In es, this message translates to:
  /// **'Seleccionar sesiones'**
  String get selectSessions;

  /// Tooltip/acción para alternar el agrupado de sesiones por temporada
  ///
  /// In es, this message translates to:
  /// **'Agrupar por temporada'**
  String get groupBySeasonTooltip;

  /// Título del diálogo y acción para asignar sesiones seleccionadas a una temporada
  ///
  /// In es, this message translates to:
  /// **'Asignar a temporada'**
  String get assignToSeason;

  /// Título/etiqueta que muestra cuántas sesiones hay seleccionadas en modo múltiple
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 sesión seleccionada} other{{count} sesiones seleccionadas}}'**
  String selectedSessionsCount(int count);

  /// Mensaje de confirmación antes de asignar sesiones seleccionadas a una temporada
  ///
  /// In es, this message translates to:
  /// **'¿Asignar {count, plural, =1{1 sesión} other{{count} sesiones}} a \"{seasonLabel}\"?'**
  String bulkAssignConfirm(int count, String seasonLabel);

  /// Mensaje de confirmación al terminar la asignación masiva de sesiones
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 sesión actualizada} other{{count} sesiones actualizadas}}'**
  String bulkAssignSuccess(int count);

  /// No description provided for @numericKeyboardLabel.
  ///
  /// In es, this message translates to:
  /// **'Numérico'**
  String get numericKeyboardLabel;

  /// No description provided for @pinKeyboardLabel.
  ///
  /// In es, this message translates to:
  /// **'Pines'**
  String get pinKeyboardLabel;

  /// No description provided for @deleteThrow.
  ///
  /// In es, this message translates to:
  /// **'Borrar tirada'**
  String get deleteThrow;

  /// No description provided for @clearPinSelection.
  ///
  /// In es, this message translates to:
  /// **'Limpiar selección'**
  String get clearPinSelection;

  /// No description provided for @restoreSeasonBeforeAssigning.
  ///
  /// In es, this message translates to:
  /// **'Restaura la temporada archivada antes de asignarle sesiones.'**
  String get restoreSeasonBeforeAssigning;

  /// No description provided for @seasonOperationFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha completado la operación. Los datos se conservan; revisa los cambios pendientes antes de reintentarlo.'**
  String get seasonOperationFailed;

  /// No description provided for @seasonRemovalExplanation.
  ///
  /// In es, this message translates to:
  /// **'No se borrará ninguna sesión. Puedes archivar la temporada o elegir el destino de sus sesiones antes de eliminarla.'**
  String get seasonRemovalExplanation;

  /// No description provided for @removeSeasonAndReassign.
  ///
  /// In es, this message translates to:
  /// **'Eliminar y reasignar'**
  String get removeSeasonAndReassign;

  /// No description provided for @retrySeasonChanges.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retrySeasonChanges;

  /// No description provided for @seasonChangesPending.
  ///
  /// In es, this message translates to:
  /// **'Cambios conservados en el dispositivo. Sesiones pendientes de confirmar en la cuenta: {count}.'**
  String seasonChangesPending(int count);

  /// No description provided for @seasonConflictsPending.
  ///
  /// In es, this message translates to:
  /// **'Conflictos que requieren revisión: {count}. No se sobrescribirán automáticamente.'**
  String seasonConflictsPending(int count);

  /// No description provided for @reviewSeasonConflict.
  ///
  /// In es, this message translates to:
  /// **'Revisar conflicto'**
  String get reviewSeasonConflict;

  /// No description provided for @localSeasonChoice.
  ///
  /// In es, this message translates to:
  /// **'Conservar temporada del dispositivo'**
  String get localSeasonChoice;

  /// No description provided for @remoteSeasonChoice.
  ///
  /// In es, this message translates to:
  /// **'Conservar temporada de la cuenta'**
  String get remoteSeasonChoice;

  /// No description provided for @backupMissingSession.
  ///
  /// In es, this message translates to:
  /// **'Respaldar sesión ausente'**
  String get backupMissingSession;

  /// No description provided for @backupMissingSessionExplanation.
  ///
  /// In es, this message translates to:
  /// **'Esta sesión está conservada en el dispositivo pero no existe en la cuenta. ¿Crear su respaldo con sus partidas? Si ya existe, no se sobrescribirá.'**
  String get backupMissingSessionExplanation;

  /// No description provided for @statisticsRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar estadísticas'**
  String get statisticsRefresh;

  /// No description provided for @statisticsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las estadísticas. Inténtalo de nuevo.'**
  String get statisticsLoadError;

  /// No description provided for @statisticsSeasonScope.
  ///
  /// In es, this message translates to:
  /// **'Resumen de temporadas completas, filtrado solo por tipo de sesión. No aplica fechas, sesión concreta ni límite de partidas. La temporada anterior se determina por su última actividad registrada. Tampoco aplica filtros de bola o bolera.'**
  String get statisticsSeasonScope;

  /// No description provided for @statisticsFilters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get statisticsFilters;

  /// No description provided for @statisticsResetFilters.
  ///
  /// In es, this message translates to:
  /// **'Restablecer filtros'**
  String get statisticsResetFilters;

  /// No description provided for @statisticsSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen del conjunto filtrado'**
  String get statisticsSummary;

  /// No description provided for @statisticsSample.
  ///
  /// In es, this message translates to:
  /// **'{games, plural, =1{1 partida} other{{games} partidas}} · {sessions, plural, =1{1 sesión} other{{sessions} sesiones}}'**
  String statisticsSample(int games, int sessions);

  /// No description provided for @statisticsRecentSample.
  ///
  /// In es, this message translates to:
  /// **'Media reciente calculada con {count, plural, =1{1 partida disponible.} other{{count} partidas disponibles.}}'**
  String statisticsRecentSample(int count);

  /// No description provided for @statisticsChartTitle.
  ///
  /// In es, this message translates to:
  /// **'Evolución de tus partidas'**
  String get statisticsChartTitle;

  /// No description provided for @statisticsScoreLegend.
  ///
  /// In es, this message translates to:
  /// **'Puntuación por partida'**
  String get statisticsScoreLegend;

  /// No description provided for @statisticsMovingLegend.
  ///
  /// In es, this message translates to:
  /// **'Media móvil ({count})'**
  String statisticsMovingLegend(int count);

  /// No description provided for @statisticsChartHint.
  ///
  /// In es, this message translates to:
  /// **'Toca un punto para consultar el resultado. El eje horizontal sigue el orden de las partidas, no los días transcurridos.'**
  String get statisticsChartHint;

  /// No description provided for @statisticsMovingNeeds.
  ///
  /// In es, this message translates to:
  /// **'La media móvil necesita al menos {count} partidas.'**
  String statisticsMovingNeeds(int count);

  /// No description provided for @statisticsGameNumber.
  ///
  /// In es, this message translates to:
  /// **'Partida {number}'**
  String statisticsGameNumber(int number);

  /// No description provided for @statisticsPreviousGame.
  ///
  /// In es, this message translates to:
  /// **'Partida anterior'**
  String get statisticsPreviousGame;

  /// No description provided for @statisticsNextGame.
  ///
  /// In es, this message translates to:
  /// **'Partida siguiente'**
  String get statisticsNextGame;

  /// No description provided for @statisticsFirstSample.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 primer tiro con pines registrados.} other{{count} primeros tiros con pines registrados.}}'**
  String statisticsFirstSample(int count);

  /// No description provided for @statisticsSpareSample.
  ///
  /// In es, this message translates to:
  /// **'{converted, plural, =1{1 convertido} other{{converted} convertidos}} de {attempts, plural, =1{1 oportunidad registrada.} other{{attempts} oportunidades registradas.}}'**
  String statisticsSpareSample(int converted, int attempts);

  /// No description provided for @statisticsPinCoverage.
  ///
  /// In es, this message translates to:
  /// **'{games} de {total} partidas con algún dato de pines; las muestras pueden ser parciales.'**
  String statisticsPinCoverage(int games, int total);

  /// No description provided for @statisticsNoPinData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos de pines. Registra tiros con el teclado de pines para consultar este desglose.'**
  String get statisticsNoPinData;

  /// No description provided for @statisticsNoSample.
  ///
  /// In es, this message translates to:
  /// **'Sin datos suficientes'**
  String get statisticsNoSample;

  /// No description provided for @statisticsSpareTableHint.
  ///
  /// In es, this message translates to:
  /// **'Cada fila muestra conversiones / oportunidades de ese deje. El mapa agrupa todos los dejes que incluyen cada pin; no equivale a remates de pin único.'**
  String get statisticsSpareTableHint;

  /// No description provided for @statisticsFilteredEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay partidas con estos filtros. Puedes cambiarlos o restablecerlos.'**
  String get statisticsFilteredEmpty;

  /// No description provided for @statisticsUnknownDate.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get statisticsUnknownDate;

  /// No description provided for @statisticsProgress.
  ///
  /// In es, this message translates to:
  /// **'Consistencia y comparación reciente'**
  String get statisticsProgress;

  /// No description provided for @statisticsDeviation.
  ///
  /// In es, this message translates to:
  /// **'Desviación de puntuaciones'**
  String get statisticsDeviation;

  /// No description provided for @statisticsDeviationNote.
  ///
  /// In es, this message translates to:
  /// **'Desviación estándar del conjunto registrado: menor significa puntuaciones más próximas entre sí, no necesariamente mejores. Se necesitan al menos dos partidas.'**
  String get statisticsDeviationNote;

  /// No description provided for @statisticsMetricPoints.
  ///
  /// In es, this message translates to:
  /// **'{value} puntos'**
  String statisticsMetricPoints(String value);

  /// No description provided for @statisticsAnalysisSample.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 partida analizada} other{{count} partidas analizadas}}'**
  String statisticsAnalysisSample(int count);

  /// No description provided for @statisticsComparisonWindow.
  ///
  /// In es, this message translates to:
  /// **'Partidas por bloque'**
  String get statisticsComparisonWindow;

  /// No description provided for @statisticsComparisonScope.
  ///
  /// In es, this message translates to:
  /// **'Compara bloques consecutivos del mismo número de partidas dentro del conjunto filtrado, incluido el límite de últimas partidas. No compara periodos de igual duración.'**
  String get statisticsComparisonScope;

  /// No description provided for @statisticsComparisonNeeds.
  ///
  /// In es, this message translates to:
  /// **'Se necesitan {required} partidas filtradas; hay {available}. No se comparan bloques incompletos.'**
  String statisticsComparisonNeeds(int required, int available);

  /// No description provided for @statisticsRecentBlock.
  ///
  /// In es, this message translates to:
  /// **'Últimas {count} partidas'**
  String statisticsRecentBlock(int count);

  /// No description provided for @statisticsPreviousBlock.
  ///
  /// In es, this message translates to:
  /// **'Las {count} partidas anteriores'**
  String statisticsPreviousBlock(int count);

  /// No description provided for @statisticsMeanChange.
  ///
  /// In es, this message translates to:
  /// **'Variación del promedio: {value} puntos'**
  String statisticsMeanChange(String value);

  /// No description provided for @statisticsChangeNote.
  ///
  /// In es, this message translates to:
  /// **'La diferencia describe estas partidas. No demuestra una mejora de habilidad ni el efecto de una bola o bolera.'**
  String get statisticsChangeNote;

  /// No description provided for @statisticsByBall.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento por bola'**
  String get statisticsByBall;

  /// No description provided for @statisticsByVenue.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento por bolera'**
  String get statisticsByVenue;

  /// No description provided for @statisticsGroupsNote.
  ///
  /// In es, this message translates to:
  /// **'Datos del conjunto filtrado, ordenados por número de partidas. Compara las muestras y las condiciones de juego; no es una clasificación de cuál es mejor.'**
  String get statisticsGroupsNote;

  /// No description provided for @statisticsAllBalls.
  ///
  /// In es, this message translates to:
  /// **'Todas las bolas'**
  String get statisticsAllBalls;

  /// No description provided for @statisticsWithoutBall.
  ///
  /// In es, this message translates to:
  /// **'Sin bola especificada'**
  String get statisticsWithoutBall;

  /// No description provided for @statisticsBallReference.
  ///
  /// In es, this message translates to:
  /// **'Bola con ID {id}'**
  String statisticsBallReference(String id);

  /// No description provided for @statisticsBallFilter.
  ///
  /// In es, this message translates to:
  /// **'Bola utilizada'**
  String get statisticsBallFilter;

  /// No description provided for @statisticsVenueFilter.
  ///
  /// In es, this message translates to:
  /// **'Bolera de la sesión'**
  String get statisticsVenueFilter;

  /// No description provided for @statisticsAllVenues.
  ///
  /// In es, this message translates to:
  /// **'Todas las boleras'**
  String get statisticsAllVenues;

  /// No description provided for @statisticsWithoutVenue.
  ///
  /// In es, this message translates to:
  /// **'Sin bolera especificada'**
  String get statisticsWithoutVenue;

  /// No description provided for @statisticsGroupSummary.
  ///
  /// In es, this message translates to:
  /// **'Promedio: {average} · Mejor: {best}'**
  String statisticsGroupSummary(String average, String best);

  /// No description provided for @ballDefault.
  ///
  /// In es, this message translates to:
  /// **'Bola predeterminada'**
  String get ballDefault;

  /// No description provided for @ballDefaultHint.
  ///
  /// In es, this message translates to:
  /// **'Se aplica a los tiros sin asignación individual. Cambiarla no elimina las excepciones por tiro.'**
  String get ballDefaultHint;

  /// No description provided for @ballPerThrow.
  ///
  /// In es, this message translates to:
  /// **'Bolas por tiro'**
  String get ballPerThrow;

  /// No description provided for @ballThrowsHint.
  ///
  /// In es, this message translates to:
  /// **'Asigna cada tiro o aplica una bola a un intervalo de frames. Los tiros no realizados no cuentan. Los cambios solo se aplican al guardar.'**
  String get ballThrowsHint;

  /// No description provided for @ballOverrideCount.
  ///
  /// In es, this message translates to:
  /// **'{count} asignaciones individuales configuradas'**
  String ballOverrideCount(int count);

  /// No description provided for @ballRangeFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde el frame'**
  String get ballRangeFrom;

  /// No description provided for @ballRangeUntil.
  ///
  /// In es, this message translates to:
  /// **'Hasta el frame'**
  String get ballRangeUntil;

  /// No description provided for @ballRangeShots.
  ///
  /// In es, this message translates to:
  /// **'Tiros del intervalo'**
  String get ballRangeShots;

  /// No description provided for @ballAllThrows.
  ///
  /// In es, this message translates to:
  /// **'Todos los tiros'**
  String get ballAllThrows;

  /// No description provided for @ballThrowNumber.
  ///
  /// In es, this message translates to:
  /// **'Tiro {number}'**
  String ballThrowNumber(int number);

  /// No description provided for @ballApplyRange.
  ///
  /// In es, this message translates to:
  /// **'Asignar bola al intervalo'**
  String get ballApplyRange;

  /// No description provided for @ballClearOverrides.
  ///
  /// In es, this message translates to:
  /// **'Restablecer a la bola predeterminada'**
  String get ballClearOverrides;

  /// No description provided for @ballSaveAssignments.
  ///
  /// In es, this message translates to:
  /// **'Guardar asignaciones'**
  String get ballSaveAssignments;

  /// No description provided for @ballAccountChanged.
  ///
  /// In es, this message translates to:
  /// **'La cuenta ha cambiado. Conserva el borrador y vuelve a abrirlo con su cuenta original.'**
  String get ballAccountChanged;

  /// No description provided for @ballScoreScope.
  ///
  /// In es, this message translates to:
  /// **'Las puntuaciones corresponden a partidas completas en las que se utilizó esta bola. En el desglose por bola, los tiros se atribuyen individualmente y los promedios solo incluyen partidas jugadas exclusivamente con ella.'**
  String get ballScoreScope;

  /// No description provided for @ballParticipation.
  ///
  /// In es, this message translates to:
  /// **'{games} partidas con uso; {exclusive} exclusivas'**
  String ballParticipation(int games, int exclusive);

  /// No description provided for @ballUsageNumbers.
  ///
  /// In es, this message translates to:
  /// **'{throws} tiros, {frames} frames con uso y {pins} pines derribados (sin bonus de puntuación).'**
  String ballUsageNumbers(int throws, int frames, int pins);

  /// No description provided for @ballStrikeSample.
  ///
  /// In es, this message translates to:
  /// **'Strikes: {converted}/{attempts} tiros con rack completo'**
  String ballStrikeSample(int converted, int attempts);

  /// No description provided for @ballSpareSample.
  ///
  /// In es, this message translates to:
  /// **'Spares: {converted}/{attempts} oportunidades de remate'**
  String ballSpareSample(int converted, int attempts);

  /// No description provided for @ballExclusiveNote.
  ///
  /// In es, this message translates to:
  /// **'Promedio y mejor partida: solo partidas jugadas exclusivamente con esta bola. No se reparte la puntuación de las partidas compartidas.'**
  String get ballExclusiveNote;

  /// No description provided for @ballNoExclusive.
  ///
  /// In es, this message translates to:
  /// **'Sin partidas exclusivas para calcular puntuaciones por bola.'**
  String get ballNoExclusive;

  /// No description provided for @ballUnknownScope.
  ///
  /// In es, this message translates to:
  /// **'Incluye partidas con algún tiro sin bola especificada, aunque otros tiros tengan una bola asignada.'**
  String get ballUnknownScope;

  /// No description provided for @photoScoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Leer marcador de una foto'**
  String get photoScoreTitle;

  /// No description provided for @photoScorePick.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar foto'**
  String get photoScorePick;

  /// No description provided for @photoScorePrivacy.
  ///
  /// In es, this message translates to:
  /// **'Lectura local en Android. La foto y el progreso de revisión se conservan solo en este dispositivo, separados por cuenta; puedes borrarlos desde esta pantalla. No se adjuntan a la partida ni se suben. ML Kit puede enviar métricas técnicas a Google, sin las fotos ni sus lecturas.'**
  String get photoScorePrivacy;

  /// No description provided for @photoScoreRegion.
  ///
  /// In es, this message translates to:
  /// **'Arrastra un rectángulo alrededor de los tiros de UN jugador y sus 10 frames, sin nombres, cabeceras ni puntuaciones acumuladas. Para ajustar una división, pulsa Editar fila y divisiones y arrastra su línea.'**
  String get photoScoreRegion;

  /// No description provided for @photoScoreExtract.
  ///
  /// In es, this message translates to:
  /// **'Leer fila seleccionada'**
  String get photoScoreExtract;

  /// No description provided for @photoScoreResetRegion.
  ///
  /// In es, this message translates to:
  /// **'Editar fila y divisiones'**
  String get photoScoreResetRegion;

  /// No description provided for @photoScoreReviewHint.
  ///
  /// In es, this message translates to:
  /// **'Comprueba cada frame con la foto y márcalo como revisado. Usa X, /, - o 0–9. ? indica lectura ambigua. No se deducen tiros desde el total.'**
  String get photoScoreReviewHint;

  /// No description provided for @photoScoreFrame.
  ///
  /// In es, this message translates to:
  /// **'Frame'**
  String get photoScoreFrame;

  /// No description provided for @photoScoreThrow.
  ///
  /// In es, this message translates to:
  /// **'Tiro'**
  String get photoScoreThrow;

  /// No description provided for @photoScoreReviewed.
  ///
  /// In es, this message translates to:
  /// **'Revisado'**
  String get photoScoreReviewed;

  /// No description provided for @photoScorePrintedTotal.
  ///
  /// In es, this message translates to:
  /// **'Total del marcador (sin hándicap)'**
  String get photoScorePrintedTotal;

  /// No description provided for @photoScoreNumbers.
  ///
  /// In es, this message translates to:
  /// **'Números leídos: elige el total correcto'**
  String get photoScoreNumbers;

  /// No description provided for @photoScoreCalculated.
  ///
  /// In es, this message translates to:
  /// **'Total calculado'**
  String get photoScoreCalculated;

  /// No description provided for @photoScoreApply.
  ///
  /// In es, this message translates to:
  /// **'Usar estos tiros'**
  String get photoScoreApply;

  /// No description provided for @photoScoreInvalidFrame.
  ///
  /// In es, this message translates to:
  /// **'Hay frames incompletos o tiros incompatibles. Corrige los campos marcados.'**
  String get photoScoreInvalidFrame;

  /// No description provided for @photoScoreTotalMissing.
  ///
  /// In es, this message translates to:
  /// **'Introduce el total del marcador: de 0 a 300, sin hándicap.'**
  String get photoScoreTotalMissing;

  /// No description provided for @photoScoreMismatch.
  ///
  /// In es, this message translates to:
  /// **'Los tiros no coinciden con el total del marcador. Comprueba que has elegido el total SIN hándicap y revisa los tiros antes de continuar.'**
  String get photoScoreMismatch;

  /// No description provided for @photoScoreReviewMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta confirmar la revisión de los 10 frames y del total.'**
  String get photoScoreReviewMissing;

  /// No description provided for @photoScoreError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido leer la foto. Prueba otra imagen o registra los tiros manualmente.'**
  String get photoScoreError;

  /// No description provided for @photoScoreSize.
  ///
  /// In es, this message translates to:
  /// **'La imagen supera 20 MB o 16 megapíxeles. Recorta el marcador o selecciona una foto más pequeña.'**
  String get photoScoreSize;

  /// No description provided for @photoScorePlatform.
  ///
  /// In es, this message translates to:
  /// **'La lectura de fotos está disponible en Android. Puedes seguir registrando la partida manualmente.'**
  String get photoScorePlatform;

  /// No description provided for @photoScoreReplaceTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Reemplazar los tiros del borrador?'**
  String get photoScoreReplaceTitle;

  /// No description provided for @photoScoreReplaceBody.
  ///
  /// In es, this message translates to:
  /// **'Se sustituirán los tiros actuales y se retirarán sus selecciones visuales de pines. Las bolas asignadas y las notas se conservan. No se guardará la partida hasta que pulses Guardar.'**
  String get photoScoreReplaceBody;

  /// No description provided for @photoScoreReplace.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar tiros'**
  String get photoScoreReplace;

  /// No description provided for @photoScoreCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get photoScoreCancel;

  /// No description provided for @photoScoreRaw.
  ///
  /// In es, this message translates to:
  /// **'Lectura'**
  String get photoScoreRaw;

  /// No description provided for @photoScoreNoRegion.
  ///
  /// In es, this message translates to:
  /// **'Selecciona primero la fila de tiros sobre la imagen.'**
  String get photoScoreNoRegion;

  /// No description provided for @photoScoreCumulative.
  ///
  /// In es, this message translates to:
  /// **'Acumulado calculado'**
  String get photoScoreCumulative;

  /// No description provided for @photoScoreMatchesThrows.
  ///
  /// In es, this message translates to:
  /// **'coincide con los tiros; verificar en la foto'**
  String get photoScoreMatchesThrows;

  /// No description provided for @photoScoreHandicapHint.
  ///
  /// In es, this message translates to:
  /// **'El marcador puede mostrar el total y el total + hándicap. Selecciona el total SIN hándicap. Que una cifra coincida con los tiros no confirma que la lectura sea correcta.'**
  String get photoScoreHandicapHint;

  /// No description provided for @photoScoreMoveZoom.
  ///
  /// In es, this message translates to:
  /// **'Mover / zoom'**
  String get photoScoreMoveZoom;

  /// No description provided for @photoScoreZoomIn.
  ///
  /// In es, this message translates to:
  /// **'Acercar'**
  String get photoScoreZoomIn;

  /// No description provided for @photoScoreZoomOut.
  ///
  /// In es, this message translates to:
  /// **'Alejar'**
  String get photoScoreZoomOut;

  /// No description provided for @photoScoreResetView.
  ///
  /// In es, this message translates to:
  /// **'Ajustar imagen'**
  String get photoScoreResetView;

  /// No description provided for @photoScoreSelectMode.
  ///
  /// In es, this message translates to:
  /// **'Modo selección: arrastra la fila o una división. Para ampliar o desplazar, cambia a Mover / zoom.'**
  String get photoScoreSelectMode;

  /// No description provided for @photoScoreMoveMode.
  ///
  /// In es, this message translates to:
  /// **'Modo vista: pellizca para ampliar y arrastra para mover. La selección no cambia.'**
  String get photoScoreMoveMode;

  /// No description provided for @photoScoreDivider.
  ///
  /// In es, this message translates to:
  /// **'División entre frames'**
  String get photoScoreDivider;

  /// No description provided for @photoScoreDividerHelp.
  ///
  /// In es, this message translates to:
  /// **'Pulsa Editar fila y divisiones para ajustar esta división con el deslizador o sobre la foto.'**
  String get photoScoreDividerHelp;

  /// No description provided for @photoScorePrevious.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get photoScorePrevious;

  /// No description provided for @photoScoreNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get photoScoreNext;

  /// No description provided for @photoScoreConfirmNext.
  ///
  /// In es, this message translates to:
  /// **'Confirmar y siguiente'**
  String get photoScoreConfirmNext;

  /// No description provided for @photoScoreConfirmFrame.
  ///
  /// In es, this message translates to:
  /// **'Confirmar frame'**
  String get photoScoreConfirmFrame;

  /// No description provided for @photoScoreCellInvalid.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get photoScoreCellInvalid;

  /// No description provided for @photoScoreMissingThrow.
  ///
  /// In es, this message translates to:
  /// **'Falta un tiro necesario para completar este frame.'**
  String get photoScoreMissingThrow;

  /// No description provided for @photoScoreUnknownSymbol.
  ///
  /// In es, this message translates to:
  /// **'Símbolo desconocido. Usa X, /, - o un número de 0 a 9.'**
  String get photoScoreUnknownSymbol;

  /// No description provided for @photoScoreUnexpectedThrow.
  ///
  /// In es, this message translates to:
  /// **'Este tiro no está permitido con los tiros anteriores. Revisa los strikes y los bonus.'**
  String get photoScoreUnexpectedThrow;

  /// No description provided for @photoScoreInvalidSpare.
  ///
  /// In es, this message translates to:
  /// **'El spare / no puede ocupar esta posición.'**
  String get photoScoreInvalidSpare;

  /// No description provided for @photoScorePinSum.
  ///
  /// In es, this message translates to:
  /// **'La suma supera los diez pines del mismo juego de bolos.'**
  String get photoScorePinSum;

  /// No description provided for @photoScoreSpareExpected.
  ///
  /// In es, this message translates to:
  /// **'Los dos tiros suman diez: marca / en el remate, tras comprobar la foto.'**
  String get photoScoreSpareExpected;

  /// No description provided for @photoScoreProgress.
  ///
  /// In es, this message translates to:
  /// **'Frames revisados'**
  String get photoScoreProgress;

  /// No description provided for @photoScoreResumeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay una revisión fotográfica guardada en este dispositivo.'**
  String get photoScoreResumeTitle;

  /// No description provided for @photoScoreResume.
  ///
  /// In es, this message translates to:
  /// **'Retomar revisión'**
  String get photoScoreResume;

  /// No description provided for @photoScoreDiscard.
  ///
  /// In es, this message translates to:
  /// **'Borrar revisión guardada'**
  String get photoScoreDiscard;

  /// No description provided for @photoScoreDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar la copia local de esta revisión?'**
  String get photoScoreDiscardTitle;

  /// No description provided for @photoScoreDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán la foto y el progreso guardados para esta cuenta. No se borrará la foto original de tu galería ni ninguna partida.'**
  String get photoScoreDiscardBody;

  /// No description provided for @photoScoreChangeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cambiar la foto o la selección?'**
  String get photoScoreChangeTitle;

  /// No description provided for @photoScoreChangeBody.
  ///
  /// In es, this message translates to:
  /// **'Una nueva lectura sustituirá las correcciones y confirmaciones de esta revisión. Las partidas guardadas no cambian.'**
  String get photoScoreChangeBody;

  /// No description provided for @photoScoreContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get photoScoreContinue;

  /// No description provided for @photoScoreDraftSaved.
  ///
  /// In es, this message translates to:
  /// **'Revisión conservada en este dispositivo.'**
  String get photoScoreDraftSaved;

  /// No description provided for @photoScoreDraftSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando revisión local…'**
  String get photoScoreDraftSaving;

  /// No description provided for @photoScoreDraftError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido conservar o recuperar la revisión local. No borres los datos de la app. Puedes seguir revisando e intentar guardarla de nuevo.'**
  String get photoScoreDraftError;

  /// No description provided for @photoScoreDraftRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar guardado local'**
  String get photoScoreDraftRetry;

  /// No description provided for @photoScoreProposalTitle.
  ///
  /// In es, this message translates to:
  /// **'Propuesta de partida'**
  String get photoScoreProposalTitle;

  /// No description provided for @photoScoreChooseRow.
  ///
  /// In es, this message translates to:
  /// **'Elige la fila del jugador que quieres registrar.'**
  String get photoScoreChooseRow;

  /// No description provided for @photoScoreRowLabel.
  ///
  /// In es, this message translates to:
  /// **'Fila'**
  String get photoScoreRowLabel;

  /// No description provided for @photoScoreCorrectReading.
  ///
  /// In es, this message translates to:
  /// **'Corregir lectura'**
  String get photoScoreCorrectReading;

  /// No description provided for @photoScoreAdjustSelection.
  ///
  /// In es, this message translates to:
  /// **'Ajustar fila y columnas'**
  String get photoScoreAdjustSelection;

  /// No description provided for @photoScoreSingleConfirm.
  ///
  /// In es, this message translates to:
  /// **'Es correcto, usar esta partida'**
  String get photoScoreSingleConfirm;

  /// No description provided for @photoScoreProposalUnknown.
  ///
  /// In es, this message translates to:
  /// **'Hay tiros incompletos o incompatibles. Corrige la lectura antes de continuar.'**
  String get photoScoreProposalUnknown;

  /// No description provided for @photoScoreProposalAmbiguous.
  ///
  /// In es, this message translates to:
  /// **'La asignación de columnas es dudosa. Ajusta la selección o revisa los frames individualmente.'**
  String get photoScoreProposalAmbiguous;

  /// No description provided for @photoScoreProposalCoherent.
  ///
  /// In es, this message translates to:
  /// **'Los tiros son válidos y suman el total mostrado. Comprueba que corresponden a la foto antes de confirmar.'**
  String get photoScoreProposalCoherent;

  /// No description provided for @photoScoreProposalCumulativeMismatch.
  ///
  /// In es, this message translates to:
  /// **'Los acumulados leídos no coinciden con los calculados. Revisa la foto y los frames individualmente.'**
  String get photoScoreProposalCumulativeMismatch;

  /// No description provided for @photoScoreReturnSummary.
  ///
  /// In es, this message translates to:
  /// **'Volver al resumen'**
  String get photoScoreReturnSummary;

  /// No description provided for @photoScoreFullPhoto.
  ///
  /// In es, this message translates to:
  /// **'Ver foto ampliada'**
  String get photoScoreFullPhoto;

  /// No description provided for @photoScoreNoProposals.
  ///
  /// In es, this message translates to:
  /// **'No se han identificado diez columnas y una fila de tiros con suficiente claridad. Selecciona la fila manualmente para continuar.'**
  String get photoScoreNoProposals;

  /// No description provided for @photoScoreReviewOriginal.
  ///
  /// In es, this message translates to:
  /// **'Revisa los diez frames y el total SIN hándicap con la foto. Confirmar pasa los tiros al formulario; todavía debes guardar la partida y la sesión.'**
  String get photoScoreReviewOriginal;

  /// No description provided for @photoScoreReread.
  ///
  /// In es, this message translates to:
  /// **'Volver a leer este frame'**
  String get photoScoreReread;

  /// No description provided for @photoScoreRereadHint.
  ///
  /// In es, this message translates to:
  /// **'Propuesta de una nueva lectura. Revisa la imagen antes de sustituir este frame; los demás no cambiarán.'**
  String get photoScoreRereadHint;

  /// No description provided for @photoScoreRereadKeep.
  ///
  /// In es, this message translates to:
  /// **'Conservar lo anterior'**
  String get photoScoreRereadKeep;

  /// No description provided for @photoScoreRereadUse.
  ///
  /// In es, this message translates to:
  /// **'Usar esta propuesta'**
  String get photoScoreRereadUse;

  /// No description provided for @photoScoreRereadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo releer el frame. Tus correcciones se conservan.'**
  String get photoScoreRereadFailed;

  /// No description provided for @photoScorePrepare.
  ///
  /// In es, this message translates to:
  /// **'Preparar foto del marcador'**
  String get photoScorePrepare;

  /// No description provided for @photoScorePrepareHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes leer la foto tal cual o enderezar el marcador. Marca sus esquinas en orden: superior izquierda, superior derecha, inferior derecha e inferior izquierda. Incluye las cabeceras 1–10, los tiros y los acumulados de los jugadores; evita el total con hándicap.'**
  String get photoScorePrepareHint;

  /// No description provided for @photoScoreCornerTL.
  ///
  /// In es, this message translates to:
  /// **'Superior izquierda'**
  String get photoScoreCornerTL;

  /// No description provided for @photoScoreCornerTR.
  ///
  /// In es, this message translates to:
  /// **'Superior derecha'**
  String get photoScoreCornerTR;

  /// No description provided for @photoScoreCornerBR.
  ///
  /// In es, this message translates to:
  /// **'Inferior derecha'**
  String get photoScoreCornerBR;

  /// No description provided for @photoScoreCornerBL.
  ///
  /// In es, this message translates to:
  /// **'Inferior izquierda'**
  String get photoScoreCornerBL;

  /// No description provided for @photoScoreCornersEdit.
  ///
  /// In es, this message translates to:
  /// **'Marcar esquinas'**
  String get photoScoreCornersEdit;

  /// No description provided for @photoScoreCornersInvalid.
  ///
  /// In es, this message translates to:
  /// **'Las esquinas no forman una región válida. Revisa su orden y separación.'**
  String get photoScoreCornersInvalid;

  /// No description provided for @photoScoreCornersReset.
  ///
  /// In es, this message translates to:
  /// **'Restablecer encuadre'**
  String get photoScoreCornersReset;

  /// No description provided for @photoScoreCornersPreview.
  ///
  /// In es, this message translates to:
  /// **'Enderezar y previsualizar'**
  String get photoScoreCornersPreview;

  /// No description provided for @photoScorePreparedPreview.
  ///
  /// In es, this message translates to:
  /// **'Comprueba que aparecen los diez frames completos y sus acumulados.'**
  String get photoScorePreparedPreview;

  /// No description provided for @photoScoreReadOriginal.
  ///
  /// In es, this message translates to:
  /// **'Leer foto sin corregir'**
  String get photoScoreReadOriginal;

  /// No description provided for @photoScoreReadPrepared.
  ///
  /// In es, this message translates to:
  /// **'Leer este encuadre'**
  String get photoScoreReadPrepared;

  /// No description provided for @photoScorePrepareFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo preparar la imagen. Ajusta las esquinas o usa la foto original.'**
  String get photoScorePrepareFailed;

  /// No description provided for @photoScorePreparePrivacy.
  ///
  /// In es, this message translates to:
  /// **'La foto original no se modifica. El borrador conservará la imagen elegida para la lectura; esta preparación no se guarda hasta leerla.'**
  String get photoScorePreparePrivacy;
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
