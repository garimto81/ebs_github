// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get commonLoading => '로딩 중...';

  @override
  String get commonSave => '저장';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonEdit => '편집';

  @override
  String get commonCreate => '생성';

  @override
  String get commonSearch => '검색';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonClose => '닫기';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonNext => '다음';

  @override
  String get commonYes => '예';

  @override
  String get commonNo => '아니오';

  @override
  String get commonEmpty => '데이터가 없습니다';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonRequired => '필수';

  @override
  String get commonOptional => '선택';

  @override
  String get layoutLogout => '로그아웃';

  @override
  String get layoutNavigation => '메뉴';

  @override
  String get layoutActiveCc => 'Active Command Centers';

  @override
  String get layoutNoCc => '활성 CC 없음';

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
  String get navLogout => '로그아웃';

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
  String get navAdmin => '관리';

  @override
  String get loginTitle => 'EBS Lobby';

  @override
  String get loginSubtitle => 'Tournament Management System';

  @override
  String get loginEmail => '이메일 주소';

  @override
  String get loginPassword => '비밀번호';

  @override
  String get loginRememberMe => '로그인 유지';

  @override
  String get loginSubmit => '로그인';

  @override
  String get loginOr => '또는';

  @override
  String get loginGoogleLogin => 'Google 로그인';

  @override
  String get loginForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get loginTwoFactor => '2단계 인증 코드';

  @override
  String get loginTwoFactorPrompt => '인증 앱에서 6자리 코드를 입력하세요';

  @override
  String get loginVerify => '인증';

  @override
  String get loginRestorePrompt => '이전 세션을 복원하시겠습니까?';

  @override
  String get loginRestoreTable => '이전 테이블:';

  @override
  String get loginRestoreContinue => '계속';

  @override
  String get loginRestoreFresh => '새로 시작';

  @override
  String get loginErrorsInvalid => '이메일 또는 비밀번호가 잘못되었습니다';

  @override
  String get loginErrorsNetwork => '서버에 연결할 수 없습니다';

  @override
  String get loginErrorsTwoFactorInvalid => '인증 코드가 올바르지 않습니다';

  @override
  String get forgotPasswordSubtitle => '가입 시 사용한 이메일을 입력하세요';

  @override
  String get forgotPasswordSubmit => '재설정 링크 전송';

  @override
  String get forgotPasswordSuccessMessage => '이메일이 등록되어 있다면 재설정 링크를 발송했습니다.';

  @override
  String get notFoundTitle => '페이지를 찾을 수 없습니다';

  @override
  String get notFoundMessage => '요청하신 페이지가 존재하지 않거나 이동되었습니다.';

  @override
  String get notFoundGoHome => '홈으로';

  @override
  String get lobbySeriesTitle => 'Series';

  @override
  String lobbySeriesTotal(int count) {
    return '$count개 Series';
  }

  @override
  String get lobbySeriesNewSeries => '새 Series';

  @override
  String get lobbySeriesEmpty => 'Series가 없습니다';

  @override
  String get lobbySeriesSearchPlaceholder => 'Series 검색...';

  @override
  String get lobbySeriesOnlyUpdated => '최근 변경';

  @override
  String get lobbySeriesBookmarks => '북마크';

  @override
  String get lobbyEventsTitle => 'Events';

  @override
  String lobbyEventsTotal(int count) {
    return '$count개 Event';
  }

  @override
  String get lobbyEventsNewEvent => '새 Event';

  @override
  String get lobbyEventsCreateTournament => '새 토너먼트 생성';

  @override
  String get lobbyEventsEmpty => 'Event가 없습니다';

  @override
  String get lobbyEventsFilterEventNo => 'Event No';

  @override
  String get lobbyEventsFilterName => '이름';

  @override
  String get lobbyEventsFilterMix => 'Mix';

  @override
  String get lobbyEventsFilterGameType => '게임 유형';

  @override
  String get lobbyEventsFilterTournType => '유형';

  @override
  String get lobbyEventsTodayEvents => '오늘의 Events';

  @override
  String get lobbyFlightsTitle => 'Flights';

  @override
  String lobbyFlightsTotal(int count) {
    return '$count개 Flight';
  }

  @override
  String get lobbyFlightsNewFlight => '새 Flight';

  @override
  String get lobbyFlightsEmpty => 'Flight가 없습니다';

  @override
  String get lobbyTablesTitle => 'Tables';

  @override
  String lobbyTablesTotal(int count) {
    return '$count개 Table';
  }

  @override
  String get lobbyTablesNewTable => '새 Table';

  @override
  String get lobbyTablesLaunchCc => 'CC 실행';

  @override
  String get lobbyTablesEmpty => 'Table이 없습니다';

  @override
  String get lobbyTablesRebalance => '리밸런스';

  @override
  String get lobbyTablesTableAction => 'Table Action';

  @override
  String get lobbyTablesSearchPlayer => '플레이어 검색...';

  @override
  String get lobbyTablesTableNo => '테이블 번호';

  @override
  String get lobbyTablesTableName => '테이블 이름';

  @override
  String get lobbyTablesMaxPlayers => '최대 인원';

  @override
  String get lobbyTablesIsFeature => 'Feature 테이블';

  @override
  String get lobbyTablesEnterCc => 'CC 진입';

  @override
  String get lobbyTablesAddPlayer => '플레이어 추가';

  @override
  String get lobbyTablesSeatMap => '좌석 배치';

  @override
  String get lobbyTablesSelectSeat => '좌석 선택';

  @override
  String get lobbyPlayersTitle => 'Players';

  @override
  String lobbyPlayersTotal(int count) {
    return '$count명';
  }

  @override
  String get lobbyPlayersEmpty => '선수가 없습니다';

  @override
  String get lobbyPlayersSearchPlaceholder => '선수 검색...';

  @override
  String get lobbyHandHistoryTitle => 'Hand History';

  @override
  String get lobbyHandHistoryEmpty => 'Hand 기록이 없습니다';

  @override
  String get lobbyHandHistorySelectTable => '테이블 선택';

  @override
  String get lobbyHandHistoryHandNo => 'Hand #';

  @override
  String get lobbyHandHistoryTime => '시간';

  @override
  String get lobbyHandHistoryBoard => '보드';

  @override
  String get lobbyHandHistoryPot => 'Pot';

  @override
  String get lobbyHandHistoryStreet => 'Street';

  @override
  String get lobbyHandHistoryPlayers => '플레이어';

  @override
  String get lobbyHandHistoryActions => '액션';

  @override
  String get lobbyHandHistorySeat => '좌석';

  @override
  String get lobbyHandHistoryPlayer => '플레이어';

  @override
  String get lobbyHandHistoryHoleCards => '핸드 카드';

  @override
  String get lobbyHandHistoryStartStack => '시작 스택';

  @override
  String get lobbyHandHistoryEndStack => '종료 스택';

  @override
  String get lobbyHandHistoryPnl => '손익';

  @override
  String get lobbyHandHistoryWinner => '승자';

  @override
  String get lobbyHandHistoryNoDetail => '상세 정보가 없습니다';

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
  String get settingsDirty => '저장되지 않은 변경사항이 있습니다';

  @override
  String get settingsRevert => '되돌리기';

  @override
  String get settingsSaved => '저장되었습니다';

  @override
  String get settingsOutputsResolution => '해상도';

  @override
  String get settingsOutputsFrameRate => '프레임 레이트';

  @override
  String get settingsOutputsOutputProtocol => '출력 프로토콜';

  @override
  String get settingsOutputsFillKeyRouting => 'Fill & Key 라우팅 활성화';

  @override
  String get settingsGfxLayoutPreset => '레이아웃 프리셋';

  @override
  String get settingsGfxCardStyle => '카드 스타일';

  @override
  String get settingsGfxPlayerDisplayOptions => '플레이어 표시 옵션';

  @override
  String get settingsGfxShowPlayerPhoto => '플레이어 사진 표시';

  @override
  String get settingsGfxShowPlayerFlag => '플레이어 국기 표시';

  @override
  String get settingsGfxShowChipCount => '칩 카운트 표시';

  @override
  String get settingsGfxAnimationSpeed => '애니메이션 속도';

  @override
  String get settingsDisplayBlindsFormat => '블라인드 표시 형식';

  @override
  String get settingsDisplayPrecisionDigits => '소수점 자릿수';

  @override
  String get settingsDisplayDisplayMode => '표시 모드';

  @override
  String get settingsRulesGameRulesTitle => '게임 규칙';

  @override
  String get settingsRulesBombPot => 'Bomb Pot';

  @override
  String get settingsRulesBombPotFrequency => 'Bomb Pot 주기';

  @override
  String get settingsRulesHands => '핸드';

  @override
  String get settingsRulesStraddle => 'Straddle';

  @override
  String get settingsRulesStraddleType => 'Straddle 유형';

  @override
  String get settingsRulesSleeper => 'Sleeper';

  @override
  String get settingsRulesPlayerDisplayTitle => '플레이어 표시';

  @override
  String get settingsRulesShowSeatNumber => '좌석 번호 표시';

  @override
  String get settingsRulesShowPlayerOrder => '플레이어 순서 표시';

  @override
  String get settingsRulesHighlightActivePlayer => '활성 플레이어 하이라이트';

  @override
  String get settingsStatsShowEquity => 'Equity 표시';

  @override
  String get settingsStatsShowOuts => 'Outs 표시';

  @override
  String get settingsStatsShowLeaderboard => 'Leaderboard 표시';

  @override
  String get settingsStatsShowScoreStrip => 'Score Strip 표시';

  @override
  String get settingsPreferencesLanguage => '언어';

  @override
  String get settingsPreferencesTablePassword => '테이블 비밀번호';

  @override
  String get settingsPreferencesDiagnostics => '진단 정보 표시';

  @override
  String get settingsPreferencesExportFolder => 'Export 폴더 경로';

  @override
  String get settingsPreferencesExportFolderPlaceholder => '/path/to/export';

  @override
  String get settingsPreferencesTwoFactorTitle => '2단계 인증 (2FA)';

  @override
  String get settingsPreferencesTwoFactorEnabled => '활성화됨';

  @override
  String get settingsPreferencesTwoFactorDisabled => '비활성화됨';

  @override
  String get settingsPreferencesTwoFactorEnable => '2FA 활성화';

  @override
  String get settingsPreferencesTwoFactorDisable => '2FA 비활성화';

  @override
  String get settingsPreferencesTwoFactorSetupTitle => '2FA 설정';

  @override
  String get settingsPreferencesTwoFactorDisableTitle => '2FA 비활성화';

  @override
  String get settingsPreferencesTwoFactorDisableWarning =>
      '2FA를 비활성화하면 계정 보안이 약해집니다. 계속하려면 현재 인증 코드를 입력하세요.';

  @override
  String get settingsPreferencesTwoFactorConfirmCode => '인증 코드 (6자리)';

  @override
  String get settingsPreferencesTwoFactorQrPlaceholder => 'QR 코드가 여기에 표시됩니다';

  @override
  String get settingsPreferencesTwoFactorManualEntry => '수동 입력 코드';

  @override
  String get graphicEditorTitle => 'Graphic Editor';

  @override
  String get graphicEditorHubSubtitle => '스킨 관리 및 Overlay 편집';

  @override
  String get graphicEditorUpload => '업로드';

  @override
  String get graphicEditorActivate => '활성화';

  @override
  String get graphicEditorDeactivate => '비활성화';

  @override
  String get graphicEditorMetadata => '메타데이터';

  @override
  String get graphicEditorPreview => '미리보기';

  @override
  String get graphicEditorEmpty => '등록된 스킨이 없습니다';

  @override
  String get graphicEditorUploadDropzone => 'Rive 파일을 여기에 드래그하거나 클릭하여 선택';

  @override
  String get graphicEditorValidationErrors => '검증 오류';

  @override
  String get graphicEditorStatus => '상태';

  @override
  String get graphicEditorVersion => '버전';

  @override
  String get graphicEditorFileSize => '파일 크기';

  @override
  String get graphicEditorUploadedAt => '업로드일';

  @override
  String get graphicEditorActivatedAt => '활성화일';

  @override
  String get graphicEditorMetaTitle => '제목';

  @override
  String get graphicEditorMetaDescription => '설명';

  @override
  String get graphicEditorMetaAuthor => '작성자';

  @override
  String get graphicEditorMetaTags => '태그';

  @override
  String get graphicEditorTagsHint => 'Enter 키로 태그 추가';

  @override
  String get auditLogTitle => '감사 로그';

  @override
  String get auditLogEmpty => '감사 로그가 없습니다';

  @override
  String get auditLogTimestamp => '시간';

  @override
  String get auditLogUser => '사용자';

  @override
  String get auditLogAction => '액션';

  @override
  String get auditLogEntity => '대상';

  @override
  String get auditLogDetails => '상세';

  @override
  String get auditLogIp => 'IP 주소';

  @override
  String get staffTitle => '스태프 관리';

  @override
  String get staffAddUser => '사용자 추가';

  @override
  String get staffEditUser => '사용자 수정';

  @override
  String get staffEmail => '이메일 주소';

  @override
  String get staffDisplayName => '표시 이름';

  @override
  String get staffPassword => '비밀번호';

  @override
  String get staffRole => '역할';

  @override
  String get staffTableAccess => '테이블 접근';

  @override
  String get staffAllTables => '모든 테이블';

  @override
  String get staffSpecificTables => '지정 테이블';

  @override
  String get staffAccountStatus => '계정 상태';

  @override
  String get staffForceLogout => '강제 로그아웃';

  @override
  String get staffConfirmForceLogout => '이 사용자를 강제 로그아웃하시겠습니까?';

  @override
  String get staffConfirmDelete => '이 사용자를 영구 삭제하시겠습니까?';

  @override
  String get errorsNotFound => '페이지를 찾을 수 없습니다';

  @override
  String get errorsForbidden => '접근 권한이 없습니다';

  @override
  String get errorsUnauthorized => '로그인이 필요합니다';

  @override
  String get errorsNetworkError => '네트워크 오류가 발생했습니다';

  @override
  String get errorsServerError => '서버 오류가 발생했습니다';

  @override
  String get errorsUnknown => '알 수 없는 오류가 발생했습니다';

  @override
  String get errorsSessionExpired => '세션이 만료되었습니다. 다시 로그인해주세요';

  @override
  String get errorsGoHome => '홈으로';
}
