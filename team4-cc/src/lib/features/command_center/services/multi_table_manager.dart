// Multi-Table Operations manager (BS-05-10).
//
// Three operator patterns:
//   A (1:1)       — single dedicated table
//   B (2-4 rotating) — operator cycles through assigned tables
//   C (0→N on-demand) — tables added/removed dynamically
//
// Only the *active* table receives keyboard shortcuts.
//
// FOCUS_MISMATCH_GUARD: 200ms suppression after OS Alt+Tab prevents
// stale keystrokes from reaching the wrong table context.
//
// Alerts:
//   • Audio beep — action required on non-focused table
//   • Window flash — CC window not focused when alert fires
//   • OS notification — table WebSocket disconnect

// ---------------------------------------------------------------------------
// Operator pattern enum
// ---------------------------------------------------------------------------

/// Multi-table assignment pattern (BS-05-10 §Patterns).
enum OperatorPattern {
  /// Pattern A: operator assigned to exactly one table.
  singleTable,

  /// Pattern B: operator rotates through 2-4 tables.
  rotating,

  /// Pattern C: tables added/removed on demand (0→N).
  onDemand,
}

// ---------------------------------------------------------------------------
// Table connection model
// ---------------------------------------------------------------------------

/// Represents a single table's connection state within a multi-table CC.
class TableConnection {
  TableConnection({
    required this.tableId,
    required this.tableName,
    this.isConnected = false,
    this.handFsmState = 'idle',
  });

  /// Unique table identifier.
  final int tableId;

  /// Human-readable table name (e.g. "Main Feature Table").
  final String tableName;

  /// Whether the WebSocket connection to this table is alive.
  bool isConnected;

  /// Current HandFSM state label (for window title / alert logic).
  String handFsmState;

  /// Whether this table is waiting for operator action.
  bool get needsAttention =>
      isConnected &&
      (handFsmState == 'preFlop' ||
          handFsmState == 'flop' ||
          handFsmState == 'turn' ||
          handFsmState == 'river');
}

// ---------------------------------------------------------------------------
// Alert type
// ---------------------------------------------------------------------------

/// Types of multi-table alerts (BS-05-10 §Alerts).
enum TableAlert {
  /// Audio beep: action required on a background table.
  actionRequired,

  /// Window flash: CC not focused when alert fires.
  windowFlash,

  /// OS notification: a table's WebSocket disconnected.
  disconnect,
}

// ---------------------------------------------------------------------------
// Alert callback signature
// ---------------------------------------------------------------------------

/// Callback invoked when a table-level alert should be surfaced.
typedef TableAlertCallback = void Function(int tableId, TableAlert alert);

// ---------------------------------------------------------------------------
// Manager
// ---------------------------------------------------------------------------

/// Manages multiple table connections within a single CC Flutter instance.
///
/// Keyboard shortcuts are only forwarded to [activeTableId]. Background
/// tables emit alerts via [onAlert] when they need attention.
class MultiTableManager {
  MultiTableManager({this.onAlert});

  /// Optional alert callback (injected by the provider layer).
  final TableAlertCallback? onAlert;

  // -- state ----------------------------------------------------------------

  final Map<int, TableConnection> _tables = {};

  int? _activeTableId;

  OperatorPattern pattern = OperatorPattern.singleTable;

  // -- focus guard ----------------------------------------------------------

  final _focusGuard = Stopwatch();

  /// Call when the OS window regains focus (e.g. after Alt+Tab).
  void onWindowFocusGained() => _focusGuard
    ..reset()
    ..start();

  /// True during the 200ms suppression window after focus gain.
  bool get isFocusGuardActive =>
      _focusGuard.isRunning && _focusGuard.elapsedMilliseconds < 200;

  // -- table management -----------------------------------------------------

  /// All table IDs currently tracked.
  Iterable<int> get tableIds => _tables.keys;

  /// The currently-focused table (receives keyboard shortcuts).
  int? get activeTableId => _activeTableId;

  /// Lookup a table connection by ID. Returns null if not tracked.
  TableConnection? getTable(int tableId) => _tables[tableId];

  /// Register a new table connection.
  void addTable(TableConnection table) {
    _tables[table.tableId] = table;
    // Auto-activate if this is the first table.
    _activeTableId ??= table.tableId;
  }

  /// Remove a table connection.
  void removeTable(int tableId) {
    _tables.remove(tableId);
    if (_activeTableId == tableId) {
      _activeTableId = _tables.keys.isEmpty ? null : _tables.keys.first;
    }
  }

  /// Switch active focus to [tableId].
  ///
  /// Only the active table receives keyboard shortcuts.
  void setActiveTable(int tableId) {
    if (!_tables.containsKey(tableId)) return;
    _activeTableId = tableId;
  }

  /// Update a table's HandFSM state and trigger alerts if needed.
  void updateHandFsmState(int tableId, String newState) {
    final table = _tables[tableId];
    if (table == null) return;

    table.handFsmState = newState;

    // If the updated table is NOT active and needs attention → alert.
    if (tableId != _activeTableId && table.needsAttention) {
      onAlert?.call(tableId, TableAlert.actionRequired);
    }
  }

  /// Update a table's connection status and trigger disconnect alert.
  void updateConnectionStatus(int tableId, {required bool connected}) {
    final table = _tables[tableId];
    if (table == null) return;

    final wasConnected = table.isConnected;
    table.isConnected = connected;

    if (wasConnected && !connected) {
      onAlert?.call(tableId, TableAlert.disconnect);
    }
  }

  // -- alerts ---------------------------------------------------------------

  /// Check all background tables and emit alerts for those needing attention.
  void checkAlerts() {
    for (final table in _tables.values) {
      if (table.tableId == _activeTableId) continue;

      if (!table.isConnected) {
        onAlert?.call(table.tableId, TableAlert.disconnect);
      } else if (table.needsAttention) {
        onAlert?.call(table.tableId, TableAlert.actionRequired);
      }
    }
  }

  // -- window title ---------------------------------------------------------

  /// Generate the OS window title for [tableId].
  ///
  /// Format: `Table #<number> — <HandFSM state>`
  String getWindowTitle(int tableId, String handFsmState) =>
      'Table #$tableId \u2014 $handFsmState';

  /// Convenience: window title for the active table.
  String? get activeWindowTitle {
    if (_activeTableId == null) return null;
    final table = _tables[_activeTableId];
    if (table == null) return null;
    return getWindowTitle(table.tableId, table.handFsmState);
  }

  // -- cycle (Pattern B) ----------------------------------------------------

  /// Cycle to the next table in rotation order (Pattern B).
  ///
  /// Returns the new active table ID, or null if no tables exist.
  int? cycleNextTable() {
    if (_tables.isEmpty) return null;

    final ids = _tables.keys.toList()..sort();
    if (_activeTableId == null) {
      _activeTableId = ids.first;
      return _activeTableId;
    }

    final currentIndex = ids.indexOf(_activeTableId!);
    final nextIndex = (currentIndex + 1) % ids.length;
    _activeTableId = ids[nextIndex];
    return _activeTableId;
  }

  /// Cycle to the previous table in rotation order (Pattern B).
  int? cyclePreviousTable() {
    if (_tables.isEmpty) return null;

    final ids = _tables.keys.toList()..sort();
    if (_activeTableId == null) {
      _activeTableId = ids.last;
      return _activeTableId;
    }

    final currentIndex = ids.indexOf(_activeTableId!);
    final prevIndex = (currentIndex - 1 + ids.length) % ids.length;
    _activeTableId = ids[prevIndex];
    return _activeTableId;
  }
}
