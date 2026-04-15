// AT-05 RFID Register screen (BS-04-05, CCR-026).
// 4x13 grid + 2 Jokers, sequential registration.
// Duplicate UID protection, deck name, POST /decks on complete.
//
// Entry: pushed from AT-01 toolbar (RFID icon).
// DeckFSM: UNREGISTERED → REGISTERING → REGISTERED/PARTIAL/MOCK.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/bo_api_client.dart';
import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/enums/deck_fsm.dart';
import '../../../rfid/abstract/i_rfid_reader.dart';
import '../../../rfid/mock/mock_rfid_reader.dart';
import '../../../rfid/providers/rfid_reader_provider.dart';

// ---------------------------------------------------------------------------
// Card model for registration grid
// ---------------------------------------------------------------------------

const _suits = ['s', 'h', 'd', 'c']; // spades, hearts, diamonds, clubs
const _ranks = [
  'A', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K',
];

class _CardEntry {
  _CardEntry({required this.suit, required this.rank});
  final String suit;
  final String rank;
  String? uid; // null = not registered

  bool get isRegistered => uid != null;
  String get label => '$rank${_suitSymbol(suit)}';

  static String _suitSymbol(String s) => switch (s) {
        's' => '\u2660',
        'h' => '\u2665',
        'd' => '\u2666',
        'c' => '\u2663',
        _ => s,
      };

  Color get suitColor => switch (suit) {
        'h' || 'd' => const Color(0xFFE53935),
        _ => Colors.white,
      };
}

// ---------------------------------------------------------------------------
// Deck Registration State
// ---------------------------------------------------------------------------

class _DeckRegState {
  _DeckRegState({
    List<_CardEntry>? cards,
    this.deckFsm = DeckFsm.unregistered,
    this.readerStatus = RfidReaderStatus.disconnected,
  }) : cards = cards ?? _buildDeck();

  final List<_CardEntry> cards;
  final DeckFsm deckFsm;
  final RfidReaderStatus readerStatus;

  int get registeredCount => cards.where((c) => c.isRegistered).length;
  int get totalCards => cards.length;
  bool get isComplete => registeredCount == totalCards;
  double get progress =>
      totalCards > 0 ? registeredCount / totalCards : 0.0;

  static List<_CardEntry> _buildDeck() {
    final deck = <_CardEntry>[];
    for (final suit in _suits) {
      for (final rank in _ranks) {
        deck.add(_CardEntry(suit: suit, rank: rank));
      }
    }
    return deck;
  }
}

// ---------------------------------------------------------------------------
// AT-05 RFID Register Screen
// ---------------------------------------------------------------------------

class At05RfidRegisterScreen extends ConsumerStatefulWidget {
  const At05RfidRegisterScreen({super.key});

  @override
  ConsumerState<At05RfidRegisterScreen> createState() =>
      _At05RfidRegisterScreenState();
}

class _At05RfidRegisterScreenState
    extends ConsumerState<At05RfidRegisterScreen> {
  late _DeckRegState _state;
  final Set<String> _usedUids = {};
  final TextEditingController _deckNameController = TextEditingController();
  bool _isSubmitting = false;
  StreamSubscription<CardDetectedEvent>? _cardSub;
  StreamSubscription<RfidReaderStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    _state = _DeckRegState();
    _initReader();
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    _cardSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  void _initReader() {
    final reader = ref.read(rfidReaderProvider);
    _updateReaderStatus(reader.status);

    _statusSub = reader.onStatusChanged.listen(_updateReaderStatus);
    _cardSub = reader.onCardDetected.listen(_onCardDetected);
  }

  void _updateReaderStatus(RfidReaderStatus status) {
    setState(() {
      _state = _DeckRegState(
        cards: _state.cards,
        deckFsm: _state.deckFsm,
        readerStatus: status,
      );
    });
  }

  void _onCardDetected(CardDetectedEvent event) {
    if (_usedUids.contains(event.uid)) {
      // Duplicate UID — show warning
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicate UID detected: ${event.uid}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Find next unregistered card
    final nextCard = _state.cards.firstWhere(
      (c) => !c.isRegistered,
      orElse: () => _state.cards.first,
    );
    if (nextCard.isRegistered) return; // All cards registered

    setState(() {
      nextCard.uid = event.uid;
      _usedUids.add(event.uid);

      final fsm = _state.isComplete
          ? DeckFsm.registered
          : DeckFsm.registering;
      _state = _DeckRegState(
        cards: _state.cards,
        deckFsm: fsm,
        readerStatus: _state.readerStatus,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMock = ref.watch(rfidReaderProvider) is MockRfidReader;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('RFID Deck Registration', style: EbsTypography.toolbarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // -- Status bar --
          _StatusBar(
            state: _state,
            isMock: isMock,
          ),

          // -- Deck name (§3 layout) --
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EbsSpacing.md,
              vertical: EbsSpacing.sm,
            ),
            child: TextField(
              controller: _deckNameController,
              enabled: !_isSubmitting,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Deck Name',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
            ),
          ),

          // -- Progress --
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EbsSpacing.md,
              vertical: EbsSpacing.sm,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_state.registeredCount} / ${_state.totalCards} cards registered',
                      style: EbsTypography.playerName,
                    ),
                    Text(
                      '${(_state.progress * 100).toStringAsFixed(0)}%',
                      style: EbsTypography.stackAmount.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: EbsSpacing.xs),
                LinearProgressIndicator(
                  value: _state.progress,
                  backgroundColor: cs.surface,
                  valueColor: AlwaysStoppedAnimation(
                    _state.isComplete ? const Color(0xFF66BB6A) : cs.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // -- Card grid --
          Expanded(
            child: _CardGrid(cards: _state.cards),
          ),

          // -- Action buttons --
          _ActionBar(
            state: _state,
            isMock: isMock,
            onAutoRegister: _handleAutoRegister,
            onComplete: _handleComplete,
            onCancel: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _handleAutoRegister() {
    final reader = ref.read(rfidReaderProvider);
    if (reader is MockRfidReader) {
      // Mark all cards as registered with mock UIDs
      setState(() {
        for (var i = 0; i < _state.cards.length; i++) {
          if (!_state.cards[i].isRegistered) {
            final uid = 'MOCK-${i.toString().padLeft(3, '0')}';
            _state.cards[i].uid = uid;
            _usedUids.add(uid);
          }
        }
        _state = _DeckRegState(
          cards: _state.cards,
          deckFsm: DeckFsm.mock,
          readerStatus: _state.readerStatus,
        );
      });
      reader.autoRegisterDeck('mock-deck-001');
    }
  }

  Future<void> _handleComplete() async {
    if (_isSubmitting) return;
    final deckName = _deckNameController.text.trim();
    if (deckName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck Name 을 입력하세요.')),
      );
      return;
    }
    if (_state.registeredCount < _state.cards.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '아직 ${_state.cards.length - _state.registeredCount}장 등록되지 않았습니다.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(boApiClientProvider);
      final payload = <Map<String, String>>[
        for (final c in _state.cards)
          if (c.uid != null) {'uid': c.uid!, 'rank': c.rank, 'suit': c.suit}
      ];
      final deckId = await api.registerDeck(
        deckName: deckName,
        cards: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck registered: $deckId')),
      );
      Navigator.of(context).pop(deckId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// =============================================================================
// Status Bar — HAL status + DeckFSM state
// =============================================================================

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.state,
    required this.isMock,
  });

  final _DeckRegState state;
  final bool isMock;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EbsSpacing.md,
        vertical: EbsSpacing.sm,
      ),
      color: cs.surface,
      child: Row(
        children: [
          // HAL status icon
          _HalStatusIcon(status: state.readerStatus, isMock: isMock),
          const SizedBox(width: EbsSpacing.sm),
          Text(
            isMock ? 'Mock Mode' : _readerStatusLabel(state.readerStatus),
            style: EbsTypography.infoBar,
          ),
          const Spacer(),
          // Deck FSM badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EbsSpacing.sm,
              vertical: EbsSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _deckFsmColor(state.deckFsm).withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _deckFsmColor(state.deckFsm).withAlpha(120),
              ),
            ),
            child: Text(
              state.deckFsm.name.toUpperCase(),
              style: EbsTypography.infoBar.copyWith(
                color: _deckFsmColor(state.deckFsm),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _readerStatusLabel(RfidReaderStatus s) => switch (s) {
        RfidReaderStatus.connected => 'Connected',
        RfidReaderStatus.connecting => 'Connecting...',
        RfidReaderStatus.disconnected => 'Disconnected',
        RfidReaderStatus.connectionFailed => 'Connection Failed',
        RfidReaderStatus.reconnecting => 'Reconnecting...',
      };

  static Color _deckFsmColor(DeckFsm fsm) => switch (fsm) {
        DeckFsm.unregistered => const Color(0xFF9E9E9E),
        DeckFsm.registering => const Color(0xFFFFA726),
        DeckFsm.registered => const Color(0xFF66BB6A),
        DeckFsm.partial => const Color(0xFFEF5350),
        DeckFsm.mock => const Color(0xFF42A5F5),
      };
}

// ---------------------------------------------------------------------------
// HAL Status Icon
// ---------------------------------------------------------------------------

class _HalStatusIcon extends StatelessWidget {
  const _HalStatusIcon({required this.status, required this.isMock});
  final RfidReaderStatus status;
  final bool isMock;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _resolve();
    return Tooltip(
      message: isMock
          ? 'Mock RFID Reader'
          : status.name,
      child: Icon(icon, color: color, size: 20),
    );
  }

  (Color, IconData) _resolve() {
    if (isMock) return (const Color(0xFF42A5F5), Icons.developer_board);
    return switch (status) {
      RfidReaderStatus.connected =>
        (const Color(0xFF66BB6A), Icons.contactless),
      RfidReaderStatus.connecting ||
      RfidReaderStatus.reconnecting =>
        (const Color(0xFFFFA726), Icons.sync),
      RfidReaderStatus.disconnected =>
        (const Color(0xFF9E9E9E), Icons.contactless_outlined),
      RfidReaderStatus.connectionFailed =>
        (const Color(0xFFE53935), Icons.error_outline),
    };
  }
}

// =============================================================================
// Card Grid — 4 suits x 13 ranks
// =============================================================================

class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.cards});
  final List<_CardEntry> cards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EbsSpacing.sm),
      child: Column(
        children: [
          for (var suitIdx = 0; suitIdx < 4; suitIdx++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    for (var rankIdx = 0; rankIdx < 13; rankIdx++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _CardCell(
                            card: cards[suitIdx * 13 + rankIdx],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardCell extends StatelessWidget {
  const _CardCell({required this.card});
  final _CardEntry card;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isReg = card.isRegistered;

    return Container(
      decoration: BoxDecoration(
        color: isReg ? Colors.white : cs.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isReg ? const Color(0xFF66BB6A) : cs.outline,
          width: isReg ? 1.5 : 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          card.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isReg ? card.suitColor : cs.onSurface.withAlpha(60),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Action Bar
// =============================================================================

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.isMock,
    required this.onAutoRegister,
    required this.onComplete,
    required this.onCancel,
  });

  final _DeckRegState state;
  final bool isMock;
  final VoidCallback onAutoRegister;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(EbsSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Cancel
          OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),

          const Spacer(),

          // Mock auto-register
          if (isMock && !state.isComplete)
            Padding(
              padding: const EdgeInsets.only(right: EbsSpacing.sm),
              child: ElevatedButton.icon(
                onPressed: onAutoRegister,
                icon: const Icon(Icons.flash_auto, size: 18),
                label: const Text('Auto-Register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                ),
              ),
            ),

          // Real mode hint
          if (!isMock && !state.isComplete)
            Padding(
              padding: const EdgeInsets.only(right: EbsSpacing.sm),
              child: Text(
                'Scan cards on reader...',
                style: EbsTypography.infoBar.copyWith(
                  color: cs.onSurface,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Complete
          ElevatedButton(
            onPressed: state.isComplete ? onComplete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
            ),
            child: const Text('Complete Registration'),
          ),
        ],
      ),
    );
  }
}
