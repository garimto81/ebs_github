// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonEmpty => 'No data';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonOptional => 'Optional';

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
  String get loginEmail => 'Email Address';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginSubmit => 'Log In';

  @override
  String get loginOr => 'or';

  @override
  String get loginGoogleLogin => 'Sign in with Google';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginTwoFactor => 'Two-Factor Code';

  @override
  String get loginTwoFactorPrompt =>
      'Enter the 6-digit code from your authenticator app';

  @override
  String get loginVerify => 'Verify';

  @override
  String get loginRestorePrompt => 'Resume previous session?';

  @override
  String get loginRestoreTable => 'Previous table:';

  @override
  String get loginRestoreContinue => 'Continue';

  @override
  String get loginRestoreFresh => 'Fresh Start';

  @override
  String get loginErrorsInvalid => 'Invalid email or password';

  @override
  String get loginErrorsNetwork => 'Cannot connect to server';

  @override
  String get loginErrorsTwoFactorInvalid => 'Invalid verification code';

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
  String get lobbySeriesOnlyUpdated => 'Only updated';

  @override
  String get lobbySeriesBookmarks => 'Bookmarks';

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
  String get lobbyTablesTableNo => 'Table No.';

  @override
  String get lobbyTablesTableName => 'Table Name';

  @override
  String get lobbyTablesMaxPlayers => 'Max Players';

  @override
  String get lobbyTablesIsFeature => 'Feature Table';

  @override
  String get lobbyTablesEnterCc => 'Enter CC';

  @override
  String get lobbyTablesAddPlayer => 'Add Player';

  @override
  String get lobbyTablesSeatMap => 'Seat Map';

  @override
  String get lobbyTablesSelectSeat => 'Select Seat';

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
  String get settingsTitle => 'Settings';

  @override
  String get settingsTabsOutputs => 'Outputs';

  @override
  String get settingsTabsGfx => 'Graphics';

  @override
  String get settingsTabsDisplay => 'Display';

  @override
  String get settingsTabsRules => 'Rules';

  @override
  String get settingsTabsStats => 'Statistics';

  @override
  String get settingsTabsPreferences => 'Preferences';

  @override
  String get settingsDirty => 'You have unsaved changes';

  @override
  String get settingsRevert => 'Revert';

  @override
  String get settingsSaved => 'Saved';

  @override
  String get settingsOutputsResolution => 'Resolution';

  @override
  String get settingsOutputsFrameRate => 'Frame Rate';

  @override
  String get settingsOutputsOutputProtocol => 'Output Protocol';

  @override
  String get settingsOutputsFillKeyRouting => 'Enable Fill & Key Routing';

  @override
  String get settingsGfxLayoutPreset => 'Layout Preset';

  @override
  String get settingsGfxCardStyle => 'Card Style';

  @override
  String get settingsGfxPlayerDisplayOptions => 'Player Display Options';

  @override
  String get settingsGfxShowPlayerPhoto => 'Show Player Photo';

  @override
  String get settingsGfxShowPlayerFlag => 'Show Player Flag';

  @override
  String get settingsGfxShowChipCount => 'Show Chip Count';

  @override
  String get settingsGfxAnimationSpeed => 'Animation Speed';

  @override
  String get settingsDisplayBlindsFormat => 'Blinds Display Format';

  @override
  String get settingsDisplayPrecisionDigits => 'Precision Digits';

  @override
  String get settingsDisplayDisplayMode => 'Display Mode';

  @override
  String get settingsRulesGameRulesTitle => 'Game Rules';

  @override
  String get settingsRulesBombPot => 'Bomb Pot';

  @override
  String get settingsRulesBombPotFrequency => 'Bomb Pot Frequency';

  @override
  String get settingsRulesHands => 'hands';

  @override
  String get settingsRulesStraddle => 'Straddle';

  @override
  String get settingsRulesStraddleType => 'Straddle Type';

  @override
  String get settingsRulesSleeper => 'Sleeper';

  @override
  String get settingsRulesPlayerDisplayTitle => 'Player Display';

  @override
  String get settingsRulesShowSeatNumber => 'Show Seat Number';

  @override
  String get settingsRulesShowPlayerOrder => 'Show Player Order';

  @override
  String get settingsRulesHighlightActivePlayer => 'Highlight Active Player';

  @override
  String get settingsStatsShowEquity => 'Show Equity';

  @override
  String get settingsStatsShowOuts => 'Show Outs';

  @override
  String get settingsStatsShowLeaderboard => 'Show Leaderboard';

  @override
  String get settingsStatsShowScoreStrip => 'Show Score Strip';

  @override
  String get settingsPreferencesLanguage => 'Language';

  @override
  String get settingsPreferencesTablePassword => 'Table Password';

  @override
  String get settingsPreferencesDiagnostics => 'Show Diagnostics';

  @override
  String get settingsPreferencesExportFolder => 'Export Folder Path';

  @override
  String get settingsPreferencesExportFolderPlaceholder => '/path/to/export';

  @override
  String get settingsPreferencesTwoFactorTitle =>
      'Two-Factor Authentication (2FA)';

  @override
  String get settingsPreferencesTwoFactorEnabled => 'Enabled';

  @override
  String get settingsPreferencesTwoFactorDisabled => 'Disabled';

  @override
  String get settingsPreferencesTwoFactorEnable => 'Enable 2FA';

  @override
  String get settingsPreferencesTwoFactorDisable => 'Disable 2FA';

  @override
  String get settingsPreferencesTwoFactorSetupTitle => 'Set Up 2FA';

  @override
  String get settingsPreferencesTwoFactorDisableTitle => 'Disable 2FA';

  @override
  String get settingsPreferencesTwoFactorDisableWarning =>
      'Disabling 2FA will reduce your account security. Enter your current authentication code to continue.';

  @override
  String get settingsPreferencesTwoFactorConfirmCode =>
      'Authentication Code (6 digits)';

  @override
  String get settingsPreferencesTwoFactorQrPlaceholder =>
      'QR code will appear here';

  @override
  String get settingsPreferencesTwoFactorManualEntry => 'Manual entry code';

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
  String get graphicEditorStatus => 'Status';

  @override
  String get graphicEditorVersion => 'Version';

  @override
  String get graphicEditorFileSize => 'File Size';

  @override
  String get graphicEditorUploadedAt => 'Uploaded';

  @override
  String get graphicEditorActivatedAt => 'Activated';

  @override
  String get graphicEditorMetaTitle => 'Title';

  @override
  String get graphicEditorMetaDescription => 'Description';

  @override
  String get graphicEditorMetaAuthor => 'Author';

  @override
  String get graphicEditorMetaTags => 'Tags';

  @override
  String get graphicEditorTagsHint => 'Press Enter to add a tag';

  @override
  String get auditLogTitle => 'Audit Logs';

  @override
  String get auditLogEmpty => 'No audit logs';

  @override
  String get auditLogTimestamp => 'Timestamp';

  @override
  String get auditLogUser => 'User';

  @override
  String get auditLogAction => 'Action';

  @override
  String get auditLogEntity => 'Entity';

  @override
  String get auditLogDetails => 'Details';

  @override
  String get auditLogIp => 'IP Address';

  @override
  String get staffTitle => 'Staff Management';

  @override
  String get staffAddUser => 'New User';

  @override
  String get staffEditUser => 'Edit User';

  @override
  String get staffEmail => 'Email Address';

  @override
  String get staffDisplayName => 'Display Name';

  @override
  String get staffPassword => 'Password';

  @override
  String get staffRole => 'Role';

  @override
  String get staffTableAccess => 'Table Access';

  @override
  String get staffAllTables => 'All Tables';

  @override
  String get staffSpecificTables => 'Specific Tables';

  @override
  String get staffAccountStatus => 'Account Status';

  @override
  String get staffForceLogout => 'Force Logout';

  @override
  String get staffConfirmForceLogout => 'Force logout this user?';

  @override
  String get staffConfirmDelete => 'Delete this user permanently?';

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
