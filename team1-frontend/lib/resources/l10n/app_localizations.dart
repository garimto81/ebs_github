import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ko.dart';

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
    Locale('ko')
  ];

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get commonEmpty;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @layoutLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get layoutLogout;

  /// No description provided for @layoutNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get layoutNavigation;

  /// No description provided for @layoutActiveCc.
  ///
  /// In en, this message translates to:
  /// **'Active Command Centers'**
  String get layoutActiveCc;

  /// No description provided for @layoutNoCc.
  ///
  /// In en, this message translates to:
  /// **'No active CC'**
  String get layoutNoCc;

  /// No description provided for @layoutNavSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get layoutNavSeries;

  /// No description provided for @layoutNavTournaments.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get layoutNavTournaments;

  /// No description provided for @layoutNavTournamentList.
  ///
  /// In en, this message translates to:
  /// **'Tournament List'**
  String get layoutNavTournamentList;

  /// No description provided for @layoutNavSeriesSettings.
  ///
  /// In en, this message translates to:
  /// **'Series Settings'**
  String get layoutNavSeriesSettings;

  /// No description provided for @layoutNavStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get layoutNavStaff;

  /// No description provided for @layoutNavStaffList.
  ///
  /// In en, this message translates to:
  /// **'Staff List'**
  String get layoutNavStaffList;

  /// No description provided for @layoutNavPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get layoutNavPlayers;

  /// No description provided for @layoutNavPlayerList.
  ///
  /// In en, this message translates to:
  /// **'Player List'**
  String get layoutNavPlayerList;

  /// No description provided for @layoutNavHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get layoutNavHistory;

  /// No description provided for @layoutNavStaffActionHistory.
  ///
  /// In en, this message translates to:
  /// **'Staff Action History'**
  String get layoutNavStaffActionHistory;

  /// No description provided for @layoutNavAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get layoutNavAuditLogs;

  /// No description provided for @layoutNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get layoutNavSettings;

  /// No description provided for @layoutNavGraphicEditor.
  ///
  /// In en, this message translates to:
  /// **'Graphic Editor'**
  String get layoutNavGraphicEditor;

  /// No description provided for @navLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get navLogout;

  /// No description provided for @navSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get navSeries;

  /// No description provided for @navPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get navPlayers;

  /// No description provided for @navHandHistory.
  ///
  /// In en, this message translates to:
  /// **'Hand History'**
  String get navHandHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navGraphicEditor.
  ///
  /// In en, this message translates to:
  /// **'Graphic Editor'**
  String get navGraphicEditor;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'EBS Lobby'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament Management System'**
  String get loginSubtitle;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginSubmit;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOr;

  /// No description provided for @loginGoogleLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginGoogleLogin;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Code'**
  String get loginTwoFactor;

  /// No description provided for @loginTwoFactorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app'**
  String get loginTwoFactorPrompt;

  /// No description provided for @loginVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get loginVerify;

  /// No description provided for @loginRestorePrompt.
  ///
  /// In en, this message translates to:
  /// **'Resume previous session?'**
  String get loginRestorePrompt;

  /// No description provided for @loginRestoreTable.
  ///
  /// In en, this message translates to:
  /// **'Previous table:'**
  String get loginRestoreTable;

  /// No description provided for @loginRestoreContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginRestoreContinue;

  /// No description provided for @loginRestoreFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh Start'**
  String get loginRestoreFresh;

  /// No description provided for @loginErrorsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get loginErrorsInvalid;

  /// No description provided for @loginErrorsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get loginErrorsNetwork;

  /// No description provided for @loginErrorsTwoFactorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get loginErrorsTwoFactorInvalid;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'If the email is registered, a reset link has been sent.'**
  String get forgotPasswordSuccessMessage;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page you requested does not exist or has been moved.'**
  String get notFoundMessage;

  /// No description provided for @notFoundGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get notFoundGoHome;

  /// No description provided for @lobbySeriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get lobbySeriesTitle;

  /// No description provided for @lobbySeriesTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} series'**
  String lobbySeriesTotal(int count);

  /// No description provided for @lobbySeriesNewSeries.
  ///
  /// In en, this message translates to:
  /// **'New Series'**
  String get lobbySeriesNewSeries;

  /// No description provided for @lobbySeriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No series'**
  String get lobbySeriesEmpty;

  /// No description provided for @lobbySeriesSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search series...'**
  String get lobbySeriesSearchPlaceholder;

  /// No description provided for @lobbySeriesOnlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Only updated'**
  String get lobbySeriesOnlyUpdated;

  /// No description provided for @lobbySeriesBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get lobbySeriesBookmarks;

  /// No description provided for @lobbyEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get lobbyEventsTitle;

  /// No description provided for @lobbyEventsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String lobbyEventsTotal(int count);

  /// No description provided for @lobbyEventsNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get lobbyEventsNewEvent;

  /// No description provided for @lobbyEventsCreateTournament.
  ///
  /// In en, this message translates to:
  /// **'Create New Tournament'**
  String get lobbyEventsCreateTournament;

  /// No description provided for @lobbyEventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get lobbyEventsEmpty;

  /// No description provided for @lobbyEventsFilterEventNo.
  ///
  /// In en, this message translates to:
  /// **'Event No'**
  String get lobbyEventsFilterEventNo;

  /// No description provided for @lobbyEventsFilterName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get lobbyEventsFilterName;

  /// No description provided for @lobbyEventsFilterMix.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get lobbyEventsFilterMix;

  /// No description provided for @lobbyEventsFilterGameType.
  ///
  /// In en, this message translates to:
  /// **'Game Type'**
  String get lobbyEventsFilterGameType;

  /// No description provided for @lobbyEventsFilterTournType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get lobbyEventsFilterTournType;

  /// No description provided for @lobbyEventsTodayEvents.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Events'**
  String get lobbyEventsTodayEvents;

  /// No description provided for @lobbyFlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get lobbyFlightsTitle;

  /// No description provided for @lobbyFlightsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} flights'**
  String lobbyFlightsTotal(int count);

  /// No description provided for @lobbyFlightsNewFlight.
  ///
  /// In en, this message translates to:
  /// **'New Flight'**
  String get lobbyFlightsNewFlight;

  /// No description provided for @lobbyFlightsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No flights'**
  String get lobbyFlightsEmpty;

  /// No description provided for @lobbyTablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get lobbyTablesTitle;

  /// No description provided for @lobbyTablesTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} tables'**
  String lobbyTablesTotal(int count);

  /// No description provided for @lobbyTablesNewTable.
  ///
  /// In en, this message translates to:
  /// **'New Table'**
  String get lobbyTablesNewTable;

  /// No description provided for @lobbyTablesLaunchCc.
  ///
  /// In en, this message translates to:
  /// **'Launch CC'**
  String get lobbyTablesLaunchCc;

  /// No description provided for @lobbyTablesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tables'**
  String get lobbyTablesEmpty;

  /// No description provided for @lobbyTablesRebalance.
  ///
  /// In en, this message translates to:
  /// **'Rebalance'**
  String get lobbyTablesRebalance;

  /// No description provided for @lobbyTablesTableAction.
  ///
  /// In en, this message translates to:
  /// **'Table Action'**
  String get lobbyTablesTableAction;

  /// No description provided for @lobbyTablesSearchPlayer.
  ///
  /// In en, this message translates to:
  /// **'Search Player...'**
  String get lobbyTablesSearchPlayer;

  /// No description provided for @lobbyTablesTableNo.
  ///
  /// In en, this message translates to:
  /// **'Table No.'**
  String get lobbyTablesTableNo;

  /// No description provided for @lobbyTablesTableName.
  ///
  /// In en, this message translates to:
  /// **'Table Name'**
  String get lobbyTablesTableName;

  /// No description provided for @lobbyTablesMaxPlayers.
  ///
  /// In en, this message translates to:
  /// **'Max Players'**
  String get lobbyTablesMaxPlayers;

  /// No description provided for @lobbyTablesIsFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature Table'**
  String get lobbyTablesIsFeature;

  /// No description provided for @lobbyTablesEnterCc.
  ///
  /// In en, this message translates to:
  /// **'Enter CC'**
  String get lobbyTablesEnterCc;

  /// No description provided for @lobbyTablesAddPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get lobbyTablesAddPlayer;

  /// No description provided for @lobbyTablesSeatMap.
  ///
  /// In en, this message translates to:
  /// **'Seat Map'**
  String get lobbyTablesSeatMap;

  /// No description provided for @lobbyTablesSelectSeat.
  ///
  /// In en, this message translates to:
  /// **'Select Seat'**
  String get lobbyTablesSelectSeat;

  /// No description provided for @lobbyPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get lobbyPlayersTitle;

  /// No description provided for @lobbyPlayersTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String lobbyPlayersTotal(int count);

  /// No description provided for @lobbyPlayersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No players'**
  String get lobbyPlayersEmpty;

  /// No description provided for @lobbyPlayersSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search players...'**
  String get lobbyPlayersSearchPlaceholder;

  /// No description provided for @lobbyHandHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand History'**
  String get lobbyHandHistoryTitle;

  /// No description provided for @lobbyHandHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hand history'**
  String get lobbyHandHistoryEmpty;

  /// No description provided for @lobbyHandHistorySelectTable.
  ///
  /// In en, this message translates to:
  /// **'Select Table'**
  String get lobbyHandHistorySelectTable;

  /// No description provided for @lobbyHandHistoryHandNo.
  ///
  /// In en, this message translates to:
  /// **'Hand #'**
  String get lobbyHandHistoryHandNo;

  /// No description provided for @lobbyHandHistoryTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get lobbyHandHistoryTime;

  /// No description provided for @lobbyHandHistoryBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get lobbyHandHistoryBoard;

  /// No description provided for @lobbyHandHistoryPot.
  ///
  /// In en, this message translates to:
  /// **'Pot'**
  String get lobbyHandHistoryPot;

  /// No description provided for @lobbyHandHistoryStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get lobbyHandHistoryStreet;

  /// No description provided for @lobbyHandHistoryPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get lobbyHandHistoryPlayers;

  /// No description provided for @lobbyHandHistoryActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get lobbyHandHistoryActions;

  /// No description provided for @lobbyHandHistorySeat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get lobbyHandHistorySeat;

  /// No description provided for @lobbyHandHistoryPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get lobbyHandHistoryPlayer;

  /// No description provided for @lobbyHandHistoryHoleCards.
  ///
  /// In en, this message translates to:
  /// **'Hole Cards'**
  String get lobbyHandHistoryHoleCards;

  /// No description provided for @lobbyHandHistoryStartStack.
  ///
  /// In en, this message translates to:
  /// **'Start Stack'**
  String get lobbyHandHistoryStartStack;

  /// No description provided for @lobbyHandHistoryEndStack.
  ///
  /// In en, this message translates to:
  /// **'End Stack'**
  String get lobbyHandHistoryEndStack;

  /// No description provided for @lobbyHandHistoryPnl.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get lobbyHandHistoryPnl;

  /// No description provided for @lobbyHandHistoryWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get lobbyHandHistoryWinner;

  /// No description provided for @lobbyHandHistoryNoDetail.
  ///
  /// In en, this message translates to:
  /// **'No detail available'**
  String get lobbyHandHistoryNoDetail;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTabsOutputs.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get settingsTabsOutputs;

  /// No description provided for @settingsTabsGfx.
  ///
  /// In en, this message translates to:
  /// **'Graphics'**
  String get settingsTabsGfx;

  /// No description provided for @settingsTabsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsTabsDisplay;

  /// No description provided for @settingsTabsRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get settingsTabsRules;

  /// No description provided for @settingsTabsStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get settingsTabsStats;

  /// No description provided for @settingsTabsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsTabsPreferences;

  /// No description provided for @settingsDirty.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get settingsDirty;

  /// No description provided for @settingsRevert.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get settingsRevert;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get settingsSaved;

  /// No description provided for @settingsOutputsResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get settingsOutputsResolution;

  /// No description provided for @settingsOutputsFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Frame Rate'**
  String get settingsOutputsFrameRate;

  /// No description provided for @settingsOutputsOutputProtocol.
  ///
  /// In en, this message translates to:
  /// **'Output Protocol'**
  String get settingsOutputsOutputProtocol;

  /// No description provided for @settingsOutputsFillKeyRouting.
  ///
  /// In en, this message translates to:
  /// **'Enable Fill & Key Routing'**
  String get settingsOutputsFillKeyRouting;

  /// No description provided for @settingsGfxLayoutPreset.
  ///
  /// In en, this message translates to:
  /// **'Layout Preset'**
  String get settingsGfxLayoutPreset;

  /// No description provided for @settingsGfxCardStyle.
  ///
  /// In en, this message translates to:
  /// **'Card Style'**
  String get settingsGfxCardStyle;

  /// No description provided for @settingsGfxPlayerDisplayOptions.
  ///
  /// In en, this message translates to:
  /// **'Player Display Options'**
  String get settingsGfxPlayerDisplayOptions;

  /// No description provided for @settingsGfxShowPlayerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Show Player Photo'**
  String get settingsGfxShowPlayerPhoto;

  /// No description provided for @settingsGfxShowPlayerFlag.
  ///
  /// In en, this message translates to:
  /// **'Show Player Flag'**
  String get settingsGfxShowPlayerFlag;

  /// No description provided for @settingsGfxShowChipCount.
  ///
  /// In en, this message translates to:
  /// **'Show Chip Count'**
  String get settingsGfxShowChipCount;

  /// No description provided for @settingsGfxAnimationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation Speed'**
  String get settingsGfxAnimationSpeed;

  /// No description provided for @settingsDisplayBlindsFormat.
  ///
  /// In en, this message translates to:
  /// **'Blinds Display Format'**
  String get settingsDisplayBlindsFormat;

  /// No description provided for @settingsDisplayPrecisionDigits.
  ///
  /// In en, this message translates to:
  /// **'Precision Digits'**
  String get settingsDisplayPrecisionDigits;

  /// No description provided for @settingsDisplayDisplayMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get settingsDisplayDisplayMode;

  /// No description provided for @settingsRulesGameRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Rules'**
  String get settingsRulesGameRulesTitle;

  /// No description provided for @settingsRulesBombPot.
  ///
  /// In en, this message translates to:
  /// **'Bomb Pot'**
  String get settingsRulesBombPot;

  /// No description provided for @settingsRulesBombPotFrequency.
  ///
  /// In en, this message translates to:
  /// **'Bomb Pot Frequency'**
  String get settingsRulesBombPotFrequency;

  /// No description provided for @settingsRulesHands.
  ///
  /// In en, this message translates to:
  /// **'hands'**
  String get settingsRulesHands;

  /// No description provided for @settingsRulesStraddle.
  ///
  /// In en, this message translates to:
  /// **'Straddle'**
  String get settingsRulesStraddle;

  /// No description provided for @settingsRulesStraddleType.
  ///
  /// In en, this message translates to:
  /// **'Straddle Type'**
  String get settingsRulesStraddleType;

  /// No description provided for @settingsRulesSleeper.
  ///
  /// In en, this message translates to:
  /// **'Sleeper'**
  String get settingsRulesSleeper;

  /// No description provided for @settingsRulesPlayerDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Player Display'**
  String get settingsRulesPlayerDisplayTitle;

  /// No description provided for @settingsRulesShowSeatNumber.
  ///
  /// In en, this message translates to:
  /// **'Show Seat Number'**
  String get settingsRulesShowSeatNumber;

  /// No description provided for @settingsRulesShowPlayerOrder.
  ///
  /// In en, this message translates to:
  /// **'Show Player Order'**
  String get settingsRulesShowPlayerOrder;

  /// No description provided for @settingsRulesHighlightActivePlayer.
  ///
  /// In en, this message translates to:
  /// **'Highlight Active Player'**
  String get settingsRulesHighlightActivePlayer;

  /// No description provided for @settingsStatsShowEquity.
  ///
  /// In en, this message translates to:
  /// **'Show Equity'**
  String get settingsStatsShowEquity;

  /// No description provided for @settingsStatsShowOuts.
  ///
  /// In en, this message translates to:
  /// **'Show Outs'**
  String get settingsStatsShowOuts;

  /// No description provided for @settingsStatsShowLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Show Leaderboard'**
  String get settingsStatsShowLeaderboard;

  /// No description provided for @settingsStatsShowScoreStrip.
  ///
  /// In en, this message translates to:
  /// **'Show Score Strip'**
  String get settingsStatsShowScoreStrip;

  /// No description provided for @settingsPreferencesLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsPreferencesLanguage;

  /// No description provided for @settingsPreferencesTablePassword.
  ///
  /// In en, this message translates to:
  /// **'Table Password'**
  String get settingsPreferencesTablePassword;

  /// No description provided for @settingsPreferencesDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Show Diagnostics'**
  String get settingsPreferencesDiagnostics;

  /// No description provided for @settingsPreferencesExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Export Folder Path'**
  String get settingsPreferencesExportFolder;

  /// No description provided for @settingsPreferencesExportFolderPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'/path/to/export'**
  String get settingsPreferencesExportFolderPlaceholder;

  /// No description provided for @settingsPreferencesTwoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication (2FA)'**
  String get settingsPreferencesTwoFactorTitle;

  /// No description provided for @settingsPreferencesTwoFactorEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsPreferencesTwoFactorEnabled;

  /// No description provided for @settingsPreferencesTwoFactorDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsPreferencesTwoFactorDisabled;

  /// No description provided for @settingsPreferencesTwoFactorEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get settingsPreferencesTwoFactorEnable;

  /// No description provided for @settingsPreferencesTwoFactorDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get settingsPreferencesTwoFactorDisable;

  /// No description provided for @settingsPreferencesTwoFactorSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up 2FA'**
  String get settingsPreferencesTwoFactorSetupTitle;

  /// No description provided for @settingsPreferencesTwoFactorDisableTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get settingsPreferencesTwoFactorDisableTitle;

  /// No description provided for @settingsPreferencesTwoFactorDisableWarning.
  ///
  /// In en, this message translates to:
  /// **'Disabling 2FA will reduce your account security. Enter your current authentication code to continue.'**
  String get settingsPreferencesTwoFactorDisableWarning;

  /// No description provided for @settingsPreferencesTwoFactorConfirmCode.
  ///
  /// In en, this message translates to:
  /// **'Authentication Code (6 digits)'**
  String get settingsPreferencesTwoFactorConfirmCode;

  /// No description provided for @settingsPreferencesTwoFactorQrPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'QR code will appear here'**
  String get settingsPreferencesTwoFactorQrPlaceholder;

  /// No description provided for @settingsPreferencesTwoFactorManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry code'**
  String get settingsPreferencesTwoFactorManualEntry;

  /// No description provided for @graphicEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Graphic Editor'**
  String get graphicEditorTitle;

  /// No description provided for @graphicEditorHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skin management & overlay editing'**
  String get graphicEditorHubSubtitle;

  /// No description provided for @graphicEditorUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get graphicEditorUpload;

  /// No description provided for @graphicEditorActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get graphicEditorActivate;

  /// No description provided for @graphicEditorDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get graphicEditorDeactivate;

  /// No description provided for @graphicEditorMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get graphicEditorMetadata;

  /// No description provided for @graphicEditorPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get graphicEditorPreview;

  /// No description provided for @graphicEditorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No skins registered'**
  String get graphicEditorEmpty;

  /// No description provided for @graphicEditorUploadDropzone.
  ///
  /// In en, this message translates to:
  /// **'Drag Rive file here or click to select'**
  String get graphicEditorUploadDropzone;

  /// No description provided for @graphicEditorValidationErrors.
  ///
  /// In en, this message translates to:
  /// **'Validation errors'**
  String get graphicEditorValidationErrors;

  /// No description provided for @graphicEditorStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get graphicEditorStatus;

  /// No description provided for @graphicEditorVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get graphicEditorVersion;

  /// No description provided for @graphicEditorFileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get graphicEditorFileSize;

  /// No description provided for @graphicEditorUploadedAt.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get graphicEditorUploadedAt;

  /// No description provided for @graphicEditorActivatedAt.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get graphicEditorActivatedAt;

  /// No description provided for @graphicEditorMetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get graphicEditorMetaTitle;

  /// No description provided for @graphicEditorMetaDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get graphicEditorMetaDescription;

  /// No description provided for @graphicEditorMetaAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get graphicEditorMetaAuthor;

  /// No description provided for @graphicEditorMetaTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get graphicEditorMetaTags;

  /// No description provided for @graphicEditorTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Press Enter to add a tag'**
  String get graphicEditorTagsHint;

  /// No description provided for @auditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogTitle;

  /// No description provided for @auditLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audit logs'**
  String get auditLogEmpty;

  /// No description provided for @auditLogTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get auditLogTimestamp;

  /// No description provided for @auditLogUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get auditLogUser;

  /// No description provided for @auditLogAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditLogAction;

  /// No description provided for @auditLogEntity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get auditLogEntity;

  /// No description provided for @auditLogDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get auditLogDetails;

  /// No description provided for @auditLogIp.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get auditLogIp;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get staffTitle;

  /// No description provided for @staffAddUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get staffAddUser;

  /// No description provided for @staffEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get staffEditUser;

  /// No description provided for @staffEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get staffEmail;

  /// No description provided for @staffDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get staffDisplayName;

  /// No description provided for @staffPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get staffPassword;

  /// No description provided for @staffRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staffRole;

  /// No description provided for @staffTableAccess.
  ///
  /// In en, this message translates to:
  /// **'Table Access'**
  String get staffTableAccess;

  /// No description provided for @staffAllTables.
  ///
  /// In en, this message translates to:
  /// **'All Tables'**
  String get staffAllTables;

  /// No description provided for @staffSpecificTables.
  ///
  /// In en, this message translates to:
  /// **'Specific Tables'**
  String get staffSpecificTables;

  /// No description provided for @staffAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get staffAccountStatus;

  /// No description provided for @staffForceLogout.
  ///
  /// In en, this message translates to:
  /// **'Force Logout'**
  String get staffForceLogout;

  /// No description provided for @staffConfirmForceLogout.
  ///
  /// In en, this message translates to:
  /// **'Force logout this user?'**
  String get staffConfirmForceLogout;

  /// No description provided for @staffConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this user permanently?'**
  String get staffConfirmDelete;

  /// No description provided for @errorsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorsNotFound;

  /// No description provided for @errorsForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get errorsForbidden;

  /// No description provided for @errorsUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get errorsUnauthorized;

  /// No description provided for @errorsNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errorsNetworkError;

  /// No description provided for @errorsServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get errorsServerError;

  /// No description provided for @errorsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorsUnknown;

  /// No description provided for @errorsSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorsSessionExpired;

  /// No description provided for @errorsGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get errorsGoHome;
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
      <String>['en', 'es', 'ko'].contains(locale.languageCode);

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
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
