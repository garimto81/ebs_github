// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonCreate => 'Crear';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get commonEmpty => 'Sin datos';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonRequired => 'Requerido';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get layoutLogout => 'Log out';

  @override
  String get layoutNavigation => 'Navigation';

  @override
  String get layoutActiveCc => 'Active Command Centers';

  @override
  String get layoutNoCc => 'No active CC';

  @override
  String get layoutNavSeries => 'Series';

  @override
  String get layoutNavTournaments => 'Tournaments';

  @override
  String get layoutNavTournamentList => 'Tournament List';

  @override
  String get layoutNavSeriesSettings => 'Series Settings';

  @override
  String get layoutNavStaff => 'Staff';

  @override
  String get layoutNavStaffList => 'Staff List';

  @override
  String get layoutNavPlayers => 'Players';

  @override
  String get layoutNavPlayerList => 'Player List';

  @override
  String get layoutNavHistory => 'History';

  @override
  String get layoutNavStaffActionHistory => 'Staff Action History';

  @override
  String get layoutNavAuditLogs => 'Audit Logs';

  @override
  String get layoutNavSettings => 'Settings';

  @override
  String get layoutNavGraphicEditor => 'Graphic Editor';

  @override
  String get navLogout => 'Log out';

  @override
  String get navSeries => 'Series';

  @override
  String get navPlayers => 'Players';

  @override
  String get navHandHistory => 'Hand History';

  @override
  String get navSettings => 'Settings';

  @override
  String get navGraphicEditor => 'Graphic Editor';

  @override
  String get navAdmin => 'Admin';

  @override
  String get loginTitle => 'EBS Lobby';

  @override
  String get loginSubtitle => 'Tournament Management System';

  @override
  String get loginEmail => 'Correo electrónico';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginRememberMe => 'Recordarme';

  @override
  String get loginSubmit => 'Iniciar sesión';

  @override
  String get loginOr => 'o';

  @override
  String get loginGoogleLogin => 'Iniciar sesión con Google';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginTwoFactor => 'Código 2FA';

  @override
  String get loginTwoFactorPrompt => 'Introduce el código de 6 dígitos';

  @override
  String get loginVerify => 'Verificar';

  @override
  String get loginRestorePrompt => '¿Reanudar sesión anterior?';

  @override
  String get loginRestoreTable => 'Previous table:';

  @override
  String get loginRestoreContinue => 'Continuar';

  @override
  String get loginRestoreFresh => 'Empezar de nuevo';

  @override
  String get loginErrorsInvalid => 'Correo o contraseña no válidos';

  @override
  String get loginErrorsNetwork => 'No se puede conectar al servidor';

  @override
  String get loginErrorsTwoFactorInvalid => 'Código inválido';

  @override
  String get forgotPasswordSubtitle => 'Enter the email you signed up with';

  @override
  String get forgotPasswordSubmit => 'Send reset link';

  @override
  String get forgotPasswordSuccessMessage =>
      'If the email is registered, a reset link has been sent.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage =>
      'The page you requested does not exist or has been moved.';

  @override
  String get notFoundGoHome => 'Go home';

  @override
  String get lobbySeriesTitle => 'Series';

  @override
  String lobbySeriesTotal(int count) {
    return '$count series';
  }

  @override
  String get lobbySeriesNewSeries => 'New Series';

  @override
  String get lobbySeriesEmpty => 'No series';

  @override
  String get lobbySeriesSearchPlaceholder => 'Search series...';

  @override
  String get lobbySeriesOnlyUpdated => 'Solo actualizados';

  @override
  String get lobbySeriesBookmarks => 'Marcadores';

  @override
  String get lobbyEventsTitle => 'Events';

  @override
  String lobbyEventsTotal(int count) {
    return '$count events';
  }

  @override
  String get lobbyEventsNewEvent => 'New Event';

  @override
  String get lobbyEventsCreateTournament => 'Create New Tournament';

  @override
  String get lobbyEventsEmpty => 'No events';

  @override
  String get lobbyEventsFilterEventNo => 'Event No';

  @override
  String get lobbyEventsFilterName => 'Name';

  @override
  String get lobbyEventsFilterMix => 'Mix';

  @override
  String get lobbyEventsFilterGameType => 'Game Type';

  @override
  String get lobbyEventsFilterTournType => 'Type';

  @override
  String get lobbyEventsTodayEvents => 'Today\'s Events';

  @override
  String get lobbyFlightsTitle => 'Flights';

  @override
  String lobbyFlightsTotal(int count) {
    return '$count flights';
  }

  @override
  String get lobbyFlightsNewFlight => 'New Flight';

  @override
  String get lobbyFlightsEmpty => 'No flights';

  @override
  String get lobbyTablesTitle => 'Tables';

  @override
  String lobbyTablesTotal(int count) {
    return '$count tables';
  }

  @override
  String get lobbyTablesNewTable => 'New Table';

  @override
  String get lobbyTablesLaunchCc => 'Launch CC';

  @override
  String get lobbyTablesEmpty => 'No tables';

  @override
  String get lobbyTablesRebalance => 'Rebalance';

  @override
  String get lobbyTablesTableAction => 'Table Action';

  @override
  String get lobbyTablesSearchPlayer => 'Search Player...';

  @override
  String get lobbyTablesTableNo => 'N.º de mesa';

  @override
  String get lobbyTablesTableName => 'Nombre de mesa';

  @override
  String get lobbyTablesMaxPlayers => 'Jugadores máx.';

  @override
  String get lobbyTablesIsFeature => 'Mesa destacada';

  @override
  String get lobbyTablesEnterCc => 'Entrar CC';

  @override
  String get lobbyTablesAddPlayer => 'Agregar jugador';

  @override
  String get lobbyTablesSeatMap => 'Mapa de asientos';

  @override
  String get lobbyTablesSelectSeat => 'Seleccionar asiento';

  @override
  String get lobbyPlayersTitle => 'Players';

  @override
  String lobbyPlayersTotal(int count) {
    return '$count players';
  }

  @override
  String get lobbyPlayersEmpty => 'No players';

  @override
  String get lobbyPlayersSearchPlaceholder => 'Search players...';

  @override
  String get lobbyHandHistoryTitle => 'Hand History';

  @override
  String get lobbyHandHistoryEmpty => 'No hand history';

  @override
  String get lobbyHandHistorySelectTable => 'Select Table';

  @override
  String get lobbyHandHistoryHandNo => 'Hand #';

  @override
  String get lobbyHandHistoryTime => 'Time';

  @override
  String get lobbyHandHistoryBoard => 'Board';

  @override
  String get lobbyHandHistoryPot => 'Pot';

  @override
  String get lobbyHandHistoryStreet => 'Street';

  @override
  String get lobbyHandHistoryPlayers => 'Players';

  @override
  String get lobbyHandHistoryActions => 'Actions';

  @override
  String get lobbyHandHistorySeat => 'Seat';

  @override
  String get lobbyHandHistoryPlayer => 'Player';

  @override
  String get lobbyHandHistoryHoleCards => 'Hole Cards';

  @override
  String get lobbyHandHistoryStartStack => 'Start Stack';

  @override
  String get lobbyHandHistoryEndStack => 'End Stack';

  @override
  String get lobbyHandHistoryPnl => 'P&L';

  @override
  String get lobbyHandHistoryWinner => 'Winner';

  @override
  String get lobbyHandHistoryNoDetail => 'No detail available';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsTabsOutputs => 'Salidas';

  @override
  String get settingsTabsGfx => 'Gráficos';

  @override
  String get settingsTabsDisplay => 'Pantalla';

  @override
  String get settingsTabsRules => 'Reglas';

  @override
  String get settingsTabsStats => 'Estadísticas';

  @override
  String get settingsTabsPreferences => 'Preferencias';

  @override
  String get settingsDirty => 'Tiene cambios sin guardar';

  @override
  String get settingsRevert => 'Revertir';

  @override
  String get settingsSaved => 'Guardado';

  @override
  String get settingsOutputsResolution => 'Resolución';

  @override
  String get settingsOutputsFrameRate => 'Tasa de fotogramas';

  @override
  String get settingsOutputsOutputProtocol => 'Protocolo de salida';

  @override
  String get settingsOutputsFillKeyRouting => 'Activar enrutamiento Fill & Key';

  @override
  String get settingsGfxLayoutPreset => 'Preset de diseño';

  @override
  String get settingsGfxCardStyle => 'Estilo de carta';

  @override
  String get settingsGfxPlayerDisplayOptions =>
      'Opciones de visualización del jugador';

  @override
  String get settingsGfxShowPlayerPhoto => 'Mostrar foto del jugador';

  @override
  String get settingsGfxShowPlayerFlag => 'Mostrar bandera del jugador';

  @override
  String get settingsGfxShowChipCount => 'Mostrar conteo de fichas';

  @override
  String get settingsGfxAnimationSpeed => 'Velocidad de animación';

  @override
  String get settingsDisplayBlindsFormat => 'Formato de ciegas';

  @override
  String get settingsDisplayPrecisionDigits => 'Dígitos de precisión';

  @override
  String get settingsDisplayDisplayMode => 'Modo de pantalla';

  @override
  String get settingsRulesGameRulesTitle => 'Reglas del juego';

  @override
  String get settingsRulesBombPot => 'Bomb Pot';

  @override
  String get settingsRulesBombPotFrequency => 'Frecuencia de Bomb Pot';

  @override
  String get settingsRulesHands => 'manos';

  @override
  String get settingsRulesStraddle => 'Straddle';

  @override
  String get settingsRulesStraddleType => 'Tipo de Straddle';

  @override
  String get settingsRulesSleeper => 'Sleeper';

  @override
  String get settingsRulesPlayerDisplayTitle => 'Visualización del jugador';

  @override
  String get settingsRulesShowSeatNumber => 'Mostrar número de asiento';

  @override
  String get settingsRulesShowPlayerOrder => 'Mostrar orden del jugador';

  @override
  String get settingsRulesHighlightActivePlayer => 'Resaltar jugador activo';

  @override
  String get settingsStatsShowEquity => 'Mostrar Equity';

  @override
  String get settingsStatsShowOuts => 'Mostrar Outs';

  @override
  String get settingsStatsShowLeaderboard => 'Mostrar Leaderboard';

  @override
  String get settingsStatsShowScoreStrip => 'Mostrar Score Strip';

  @override
  String get settingsPreferencesLanguage => 'Idioma';

  @override
  String get settingsPreferencesTablePassword => 'Contraseña de mesa';

  @override
  String get settingsPreferencesDiagnostics => 'Mostrar diagnósticos';

  @override
  String get settingsPreferencesExportFolder =>
      'Ruta de carpeta de exportación';

  @override
  String get settingsPreferencesExportFolderPlaceholder => '/ruta/a/exportar';

  @override
  String get settingsPreferencesTwoFactorTitle =>
      'Autenticación de dos factores (2FA)';

  @override
  String get settingsPreferencesTwoFactorEnabled => 'Activado';

  @override
  String get settingsPreferencesTwoFactorDisabled => 'Desactivado';

  @override
  String get settingsPreferencesTwoFactorEnable => 'Activar 2FA';

  @override
  String get settingsPreferencesTwoFactorDisable => 'Desactivar 2FA';

  @override
  String get settingsPreferencesTwoFactorSetupTitle => 'Configurar 2FA';

  @override
  String get settingsPreferencesTwoFactorDisableTitle => 'Desactivar 2FA';

  @override
  String get settingsPreferencesTwoFactorDisableWarning =>
      'Desactivar 2FA reducirá la seguridad de su cuenta. Introduzca su código de autenticación actual para continuar.';

  @override
  String get settingsPreferencesTwoFactorConfirmCode =>
      'Código de autenticación (6 dígitos)';

  @override
  String get settingsPreferencesTwoFactorQrPlaceholder =>
      'El código QR aparecerá aquí';

  @override
  String get settingsPreferencesTwoFactorManualEntry =>
      'Código de entrada manual';

  @override
  String get graphicEditorTitle => 'Graphic Editor';

  @override
  String get graphicEditorHubSubtitle => 'Skin management & overlay editing';

  @override
  String get graphicEditorUpload => 'Upload';

  @override
  String get graphicEditorActivate => 'Activate';

  @override
  String get graphicEditorDeactivate => 'Deactivate';

  @override
  String get graphicEditorMetadata => 'Metadata';

  @override
  String get graphicEditorPreview => 'Preview';

  @override
  String get graphicEditorEmpty => 'No skins registered';

  @override
  String get graphicEditorUploadDropzone =>
      'Drag Rive file here or click to select';

  @override
  String get graphicEditorValidationErrors => 'Validation errors';

  @override
  String get graphicEditorStatus => 'Estado';

  @override
  String get graphicEditorVersion => 'Versión';

  @override
  String get graphicEditorFileSize => 'Tamaño de archivo';

  @override
  String get graphicEditorUploadedAt => 'Subido';

  @override
  String get graphicEditorActivatedAt => 'Activado';

  @override
  String get graphicEditorMetaTitle => 'Título';

  @override
  String get graphicEditorMetaDescription => 'Descripción';

  @override
  String get graphicEditorMetaAuthor => 'Autor';

  @override
  String get graphicEditorMetaTags => 'Etiquetas';

  @override
  String get graphicEditorTagsHint => 'Presione Enter para agregar etiqueta';

  @override
  String get auditLogTitle => 'Registros de auditoría';

  @override
  String get auditLogEmpty => 'Sin registros de auditoría';

  @override
  String get auditLogTimestamp => 'Hora';

  @override
  String get auditLogUser => 'Usuario';

  @override
  String get auditLogAction => 'Acción';

  @override
  String get auditLogEntity => 'Entidad';

  @override
  String get auditLogDetails => 'Detalles';

  @override
  String get auditLogIp => 'Dirección IP';

  @override
  String get staffTitle => 'Gestión de personal';

  @override
  String get staffAddUser => 'Nuevo usuario';

  @override
  String get staffEditUser => 'Editar usuario';

  @override
  String get staffEmail => 'Correo electrónico';

  @override
  String get staffDisplayName => 'Nombre';

  @override
  String get staffPassword => 'Contraseña';

  @override
  String get staffRole => 'Rol';

  @override
  String get staffTableAccess => 'Acceso a mesas';

  @override
  String get staffAllTables => 'Todas las mesas';

  @override
  String get staffSpecificTables => 'Mesas específicas';

  @override
  String get staffAccountStatus => 'Estado de cuenta';

  @override
  String get staffForceLogout => 'Cerrar sesión forzada';

  @override
  String get staffConfirmForceLogout => '¿Cerrar sesión de este usuario?';

  @override
  String get staffConfirmDelete => '¿Eliminar este usuario permanentemente?';

  @override
  String get errorsNotFound => 'Page not found';

  @override
  String get errorsForbidden => 'Access denied';

  @override
  String get errorsUnauthorized => 'Login required';

  @override
  String get errorsNetworkError => 'Network error';

  @override
  String get errorsServerError => 'Server error';

  @override
  String get errorsUnknown => 'Unknown error';

  @override
  String get errorsSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorsGoHome => 'Go home';
}
