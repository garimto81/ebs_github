// SeatNotifier unit tests (BS-05-03 — 10-seat state management).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/seat_provider.dart';
import 'package:ebs_cc/models/enums/seat_status.dart';

void main() {
  late ProviderContainer container;
  late SeatNotifier notifier;

  PlayerInfo _player(int id, {String name = 'Player', int stack = 10000}) =>
      PlayerInfo(id: id, name: '$name $id', stack: stack, countryCode: 'US');

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(seatsProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('SeatNotifier — initial state', () {
    test('10 empty seats (S1-S10)', () {
      final seats = container.read(seatsProvider);
      expect(seats.length, 10);

      for (var i = 0; i < 10; i++) {
        expect(seats[i].seatNo, i + 1);
        expect(seats[i].isEmpty, isTrue);
        expect(seats[i].isOccupied, isFalse);
        expect(seats[i].status, SeatStatus.empty);
        expect(seats[i].player, isNull);
        expect(seats[i].isDealer, isFalse);
        expect(seats[i].actionOn, isFalse);
        expect(seats[i].holeCards, isEmpty);
        expect(seats[i].currentBet, 0);
      }
    });
  });

  group('SeatNotifier — seatPlayer', () {
    test('empty -> occupied with player info', () {
      notifier.seatPlayer(1, _player(100));
      final seat = container.read(seatsProvider)[0];

      expect(seat.isOccupied, isTrue);
      expect(seat.isEmpty, isFalse);
      expect(seat.player!.id, 100);
      expect(seat.player!.name, 'Player 100');
      expect(seat.player!.stack, 10000);
      expect(seat.status, SeatStatus.newSeat);
      expect(seat.activity, PlayerActivity.active);
    });
  });

  group('SeatNotifier — vacateSeat', () {
    test('occupied -> empty', () {
      notifier.seatPlayer(3, _player(200));
      notifier.setDealer(3);
      notifier.setHoleCards(3, [
        const HoleCard(suit: 's', rank: 'A'),
        const HoleCard(suit: 'h', rank: 'K'),
      ]);

      notifier.vacateSeat(3);
      final seat = container.read(seatsProvider)[2];

      expect(seat.isEmpty, isTrue);
      expect(seat.player, isNull);
      expect(seat.status, SeatStatus.empty);
      expect(seat.isDealer, isFalse);
      expect(seat.holeCards, isEmpty);
      expect(seat.currentBet, 0);
      expect(seat.actionOn, isFalse);
    });
  });

  group('SeatNotifier — moveSeat', () {
    test('swap: player moves from seat A to seat B', () {
      notifier.seatPlayer(2, _player(300, name: 'Mover'));
      notifier.moveSeat(2, 7);

      final seats = container.read(seatsProvider);
      // Source vacated
      expect(seats[1].isEmpty, isTrue);
      expect(seats[1].player, isNull);

      // Destination occupied with moved status
      expect(seats[6].isOccupied, isTrue);
      expect(seats[6].player!.id, 300);
      expect(seats[6].player!.name, 'Mover 300');
      expect(seats[6].status, SeatStatus.moved);
    });

    test('moveSeat from empty seat does nothing', () {
      notifier.moveSeat(1, 5);
      final seats = container.read(seatsProvider);
      expect(seats[0].isEmpty, isTrue);
      expect(seats[4].isEmpty, isTrue);
    });
  });

  group('SeatNotifier — toggleSitOut', () {
    test('active -> sittingOut', () {
      notifier.seatPlayer(5, _player(400));
      notifier.toggleSitOut(5);
      final seat = container.read(seatsProvider)[4];
      expect(seat.activity, PlayerActivity.sittingOut);
    });

    test('sittingOut -> active', () {
      notifier.seatPlayer(5, _player(400));
      notifier.toggleSitOut(5); // active -> sittingOut
      notifier.toggleSitOut(5); // sittingOut -> active
      final seat = container.read(seatsProvider)[4];
      expect(seat.activity, PlayerActivity.active);
    });
  });

  group('SeatNotifier — setDealer', () {
    test('only one seat is dealer', () {
      notifier.seatPlayer(1, _player(100));
      notifier.seatPlayer(5, _player(500));
      notifier.seatPlayer(10, _player(1000));

      notifier.setDealer(5);
      var seats = container.read(seatsProvider);
      expect(seats.where((s) => s.isDealer).length, 1);
      expect(seats[4].isDealer, isTrue);

      // Move dealer to seat 10
      notifier.setDealer(10);
      seats = container.read(seatsProvider);
      expect(seats.where((s) => s.isDealer).length, 1);
      expect(seats[4].isDealer, isFalse);
      expect(seats[9].isDealer, isTrue);
    });
  });

  group('SeatNotifier — setActionOn', () {
    test('only one seat has actionOn', () {
      notifier.seatPlayer(2, _player(200));
      notifier.seatPlayer(7, _player(700));

      notifier.setActionOn(2);
      var seats = container.read(seatsProvider);
      expect(seats.where((s) => s.actionOn).length, 1);
      expect(seats[1].actionOn, isTrue);

      // Move action to seat 7
      notifier.setActionOn(7);
      seats = container.read(seatsProvider);
      expect(seats.where((s) => s.actionOn).length, 1);
      expect(seats[1].actionOn, isFalse);
      expect(seats[6].actionOn, isTrue);
    });

    test('setActionOn(null) clears all', () {
      notifier.seatPlayer(3, _player(300));
      notifier.setActionOn(3);
      notifier.setActionOn(null);
      final seats = container.read(seatsProvider);
      expect(seats.where((s) => s.actionOn).length, 0);
    });
  });

  group('SeatNotifier — setHoleCards', () {
    test('assigns cards to seat', () {
      notifier.seatPlayer(4, _player(400));
      notifier.setHoleCards(4, [
        const HoleCard(suit: 's', rank: 'A'),
        const HoleCard(suit: 'h', rank: 'K'),
      ]);

      final seat = container.read(seatsProvider)[3];
      expect(seat.holeCards.length, 2);
      expect(seat.holeCards[0].rank, 'A');
      expect(seat.holeCards[0].suit, 's');
      expect(seat.holeCards[1].rank, 'K');
      expect(seat.holeCards[1].suit, 'h');
    });

    test('clearAllCards removes all holecards', () {
      notifier.seatPlayer(1, _player(100));
      notifier.seatPlayer(5, _player(500));
      notifier.setHoleCards(1, [const HoleCard(suit: 's', rank: 'A')]);
      notifier.setHoleCards(5, [const HoleCard(suit: 'h', rank: 'K')]);

      notifier.clearAllCards();
      final seats = container.read(seatsProvider);
      for (final s in seats) {
        expect(s.holeCards, isEmpty);
      }
    });
  });

  group('SeatNotifier — derived providers', () {
    test('activePlayerCount counts non-empty, non-sitting-out', () {
      notifier.seatPlayer(1, _player(100));
      notifier.seatPlayer(2, _player(200));
      notifier.seatPlayer(3, _player(300));
      notifier.toggleSitOut(3); // sitting out

      final count = container.read(activePlayerCountProvider);
      expect(count, 2); // seats 1 and 2 active
    });

    test('dealerSeatProvider returns dealer seat number', () {
      notifier.seatPlayer(5, _player(500));
      notifier.setDealer(5);

      expect(container.read(dealerSeatProvider), 5);
    });

    test('dealerSeatProvider returns null when no dealer', () {
      expect(container.read(dealerSeatProvider), isNull);
    });

    test('actionOnSeatProvider returns action seat number', () {
      notifier.seatPlayer(8, _player(800));
      notifier.setActionOn(8);

      expect(container.read(actionOnSeatProvider), 8);
    });

    test('actionOnSeatProvider returns null when no action', () {
      expect(container.read(actionOnSeatProvider), isNull);
    });
  });

  group('SeatNotifier — additional operations', () {
    test('updateStack modifies player stack', () {
      notifier.seatPlayer(1, _player(100, stack: 5000));
      notifier.updateStack(1, 12000);

      final seat = container.read(seatsProvider)[0];
      expect(seat.player!.stack, 12000);
    });

    test('setCurrentBet and clearBets', () {
      notifier.seatPlayer(1, _player(100));
      notifier.seatPlayer(2, _player(200));
      notifier.setCurrentBet(1, 500);
      notifier.setCurrentBet(2, 1000);

      var seats = container.read(seatsProvider);
      expect(seats[0].currentBet, 500);
      expect(seats[1].currentBet, 1000);

      notifier.clearBets();
      seats = container.read(seatsProvider);
      for (final s in seats) {
        expect(s.currentBet, 0);
      }
    });

    test('setActivity changes player activity', () {
      notifier.seatPlayer(1, _player(100));
      notifier.setActivity(1, PlayerActivity.folded);
      expect(
        container.read(seatsProvider)[0].activity,
        PlayerActivity.folded,
      );

      notifier.setActivity(1, PlayerActivity.allIn);
      expect(
        container.read(seatsProvider)[0].activity,
        PlayerActivity.allIn,
      );
    });

    test('promoteToPlaying changes status', () {
      notifier.seatPlayer(1, _player(100));
      expect(container.read(seatsProvider)[0].status, SeatStatus.newSeat);
      notifier.promoteToPlaying(1);
      expect(container.read(seatsProvider)[0].status, SeatStatus.playing);
    });

    test('bustPlayer changes status', () {
      notifier.seatPlayer(1, _player(100));
      notifier.bustPlayer(1);
      expect(container.read(seatsProvider)[0].status, SeatStatus.busted);
    });

    test('resetAll returns to 10 empty seats', () {
      notifier.seatPlayer(1, _player(100));
      notifier.seatPlayer(5, _player(500));
      notifier.setDealer(1);

      notifier.resetAll();
      final seats = container.read(seatsProvider);
      expect(seats.length, 10);
      for (final s in seats) {
        expect(s.isEmpty, isTrue);
        expect(s.isDealer, isFalse);
      }
    });
  });

  group('HoleCard value object', () {
    test('equality by suit and rank', () {
      const c1 = HoleCard(suit: 's', rank: 'A');
      const c2 = HoleCard(suit: 's', rank: 'A');
      const c3 = HoleCard(suit: 'h', rank: 'A');

      expect(c1, equals(c2));
      expect(c1, isNot(equals(c3)));
    });

    test('toString returns rank+suit', () {
      const c = HoleCard(suit: 'd', rank: 'K');
      expect(c.toString(), 'Kd');
    });
  });
}
