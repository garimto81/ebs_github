// Global constants for ebs_cc.

class AppConstants {
  AppConstants._();

  /// Overlay broadcast target FPS.
  static const overlayTargetFps = 60;

  /// Minimum supported window width (AT-01 Main, BS-05-00 §반응형).
  static const minWindowWidthPx = 720;

  /// BO WebSocket reconnect backoff (CCR-022 §9).
  static const reconnectBackoffMs = [0, 5000, 10000];
  static const maxReconnectAttempts = 101;

  /// LocalEventBuffer capacity (BS-05-00 §BO 복구).
  static const localEventBufferCapacity = 20;

  /// Undo: unlimited within current hand (UI-02 화면 5, 2026-04-13 변경).
  /// 기존 5단계 제한 제거. 페이지네이션 10개/페이지.
  static const undoPageSize = 10;

  /// Hand History: 10핸드/페이지 (UI-02 화면 6).
  static const handHistoryPageSize = 10;

  /// 합성 카드 셀 크기 (UI-02 화면 3, 2026-04-13 변경).
  static const cardCellWidth = 60.0;
  static const cardCellHeight = 72.0;
}
