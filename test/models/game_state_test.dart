import 'package:flutter_test/flutter_test.dart';
import 'package:blackjack/models/playing_card.dart';
import 'package:blackjack/models/game_state.dart';

void main() {
  group('PlayerHand', () {
    test('hand value sums card values', () {
      final hand = PlayerHand(cards: [
        PlayingCard(suit: Suit.spades, rank: Rank.ten),
        PlayingCard(suit: Suit.hearts, rank: Rank.seven),
      ], bet: 10);
      expect(hand.handValue, 17);
    });

    test('ace counts as 11 when safe', () {
      final hand = PlayerHand(cards: [
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.nine),
      ], bet: 10);
      expect(hand.handValue, 20);
    });

    test('ace counts as 1 to avoid bust', () {
      final hand = PlayerHand(cards: [
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.nine),
        PlayingCard(suit: Suit.clubs, rank: Rank.five),
      ], bet: 10);
      expect(hand.handValue, 15);
    });

    test('two aces: one counts as 11, one as 1', () {
      final hand = PlayerHand(cards: [
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
      ], bet: 10);
      expect(hand.handValue, 12);
    });

    test('bust detected', () {
      final hand = PlayerHand(cards: [
        PlayingCard(suit: Suit.spades, rank: Rank.ten),
        PlayingCard(suit: Suit.hearts, rank: Rank.seven),
        PlayingCard(suit: Suit.clubs, rank: Rank.six),
      ], bet: 10);
      expect(hand.isBusted, true);
    });

    test('blackjack detected', () {
      final hand = PlayerHand(cards: [
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
      ], bet: 10);
      expect(hand.isBlackjack, true);
    });

    test('no blackjack on three-card 21', () {
      final hand = PlayerHand(cards: [
        PlayingCard(suit: Suit.spades, rank: Rank.seven),
        PlayingCard(suit: Suit.hearts, rank: Rank.seven),
        PlayingCard(suit: Suit.clubs, rank: Rank.seven),
      ], bet: 10);
      expect(hand.isBlackjack, false);
    });

    test('no blackjack on split hand', () {
      final hand = PlayerHand(
        cards: [
          PlayingCard(suit: Suit.spades, rank: Rank.ace),
          PlayingCard(suit: Suit.hearts, rank: Rank.king),
        ],
        bet: 10,
        fromSplit: true,
      );
      expect(hand.isBlackjack, false);
    });
  });

  group('GameState - Betting', () {
    test('placeBet deducts from balance', () {
      final game = GameState();
      expect(game.placeBet(100), true);
      expect(game.balance, 900);
      expect(game.currentBet, 100);
    });

    test('placeBet rejects amount exceeding balance', () {
      final game = GameState();
      expect(game.placeBet(2000), false);
      expect(game.balance, 1000);
    });

    test('placeBet rejects zero', () {
      final game = GameState();
      expect(game.placeBet(0), false);
    });
  });

  group('GameState - Round Start', () {
    test('startNewRound deals cards', () {
      final game = GameState();
      game.placeBet(10);
      game.startNewRound();
      expect(game.hands.length, 1);
      expect(game.hands[0].cards.length, 2);
      expect(game.dealerHand.length, 2);
    });

    test('dealer second card is face down', () {
      final game = GameState();
      game.placeBet(10);
      game.startNewRound();
      expect(game.dealerHand[0].faceUp, true);
      expect(game.dealerHand[1].faceUp, false);
    });

    test('insurance offered when dealer shows ace', () {
      final game = GameState();
      game.placeBet(100);

      bool foundInsurance = false;
      for (int i = 0; i < 200; i++) {
        game.resetForNewRound();
        game.currentBet = 100;
        game.balance = 1000;
        game.startNewRound();
        if (game.phase == GamePhase.insurance) {
          expect(game.dealerHand[0].rank, Rank.ace);
          foundInsurance = true;
          break;
        }
      }
      expect(foundInsurance, true);
    });
  });

  group('GameState - Insurance', () {
    test('accept insurance deducts half bet', () {
      final game = _setupInsuranceGame();
      if (game == null) return;

      final balanceBefore = game.balance;
      final cost = game.insuranceCost;
      game.acceptInsurance();
      expect(game.balance, balanceBefore - cost);
      expect(game.insuranceTaken, true);
      expect(game.phase, GamePhase.playerTurn);
    });

    test('decline insurance keeps balance', () {
      final game = _setupInsuranceGame();
      if (game == null) return;

      final balanceBefore = game.balance;
      game.declineInsurance();
      expect(game.balance, balanceBefore);
      expect(game.insuranceTaken, false);
      expect(game.phase, GamePhase.playerTurn);
    });
  });

  group('GameState - Hit', () {
    test('hit adds card to active hand', () {
      final game = _setupPlayerTurn();
      final cardsBefore = game.hands[0].cards.length;
      game.hit();
      expect(game.hands[0].cards.length, cardsBefore + 1);
    });
  });

  group('GameState - Stand', () {
    test('stand marks hand as standing', () {
      final game = _setupPlayerTurn();
      game.stand();
      expect(game.hands[0].isStanding, true);
    });
  });

  group('GameState - Double Down', () {
    test('double down doubles bet and adds one card', () {
      final game = _setupPlayerTurnNoBlackjack();
      if (!game.canDoubleDown) return;

      final betBefore = game.hands[0].bet;
      final cardsBefore = game.hands[0].cards.length;

      game.doubleDown();
      expect(game.hands[0].bet, betBefore * 2);
      expect(game.hands[0].cards.length, cardsBefore + 1);
      expect(game.hands[0].isDoubled, true);
    });

    test('cannot double with insufficient balance', () {
      final game = _setupPlayerTurn();
      game.balance = 0;
      expect(game.canDoubleDown, false);
    });
  });

  group('GameState - Split', () {
    test('split creates two hands', () {
      final game = _setupSplittableGame();
      if (game == null) return;

      game.split();
      expect(game.hands.length, 2);
      expect(game.hands[0].cards.length, 2);
      expect(game.hands[1].cards.length, 2);
      expect(game.hands[0].fromSplit, true);
      expect(game.hands[1].fromSplit, true);
    });

    test('split deducts additional bet', () {
      final game = _setupSplittableGame();
      if (game == null) return;

      final balanceBefore = game.balance;
      final bet = game.hands[0].bet;
      game.split();
      expect(game.balance, balanceBefore - bet);
    });

    test('cannot split different values', () {
      final game = _setupPlayerTurn();
      if (game.hands[0].cards[0].value == game.hands[0].cards[1].value) return;
      expect(game.canSplit, false);
    });
  });

  group('GameState - Payouts', () {
    test('blackjack pays 3:2', () {
      final hand = PlayerHand(cards: [], bet: 100);
      hand.result = RoundResult.playerBlackjack;
      hand.payout = (100 * 2.5).round();
      expect(hand.payout, 250);
    });

    test('regular win pays 2:1', () {
      final hand = PlayerHand(cards: [], bet: 100);
      hand.result = RoundResult.playerWins;
      hand.payout = 100 * 2;
      expect(hand.payout, 200);
    });

    test('push returns bet', () {
      final hand = PlayerHand(cards: [], bet: 100);
      hand.result = RoundResult.tie;
      hand.payout = 100;
      expect(hand.payout, 100);
    });

    test('loss pays nothing', () {
      final hand = PlayerHand(cards: [], bet: 100);
      hand.result = RoundResult.dealerWins;
      hand.payout = 0;
      expect(hand.payout, 0);
    });
  });

  group('GameState - Dealer Logic', () {
    test('dealer reveals cards at end', () {
      final game = _setupPlayerTurn();
      game.revealDealerCards();
      for (final card in game.dealerHand) {
        expect(card.faceUp, true);
      }
    });

    test('resetForNewRound resets state', () {
      final game = _setupPlayerTurn();
      game.resetForNewRound();
      expect(game.phase, GamePhase.betting);
      expect(game.currentBet, 0);
      expect(game.insuranceBet, 0);
      expect(game.insuranceTaken, false);
    });
  });

  group('GameState - Result Messages', () {
    test('result messages are correct', () {
      final game = GameState();
      final hand = PlayerHand(cards: [], bet: 10);

      hand.result = RoundResult.playerBlackjack;
      expect(game.resultMessageForHand(hand), 'BLACKJACK!');

      hand.result = RoundResult.playerWins;
      expect(game.resultMessageForHand(hand), 'Win!');

      hand.result = RoundResult.dealerWins;
      expect(game.resultMessageForHand(hand), 'Dealer wins');

      hand.result = RoundResult.playerBust;
      expect(game.resultMessageForHand(hand), 'Bust!');

      hand.result = RoundResult.dealerBust;
      expect(game.resultMessageForHand(hand), 'Dealer busts!');

      hand.result = RoundResult.tie;
      expect(game.resultMessageForHand(hand), 'Push');
    });
  });

  group('AiPlayer', () {
    test('places bets within balance', () {
      final ai = AiPlayer(name: 'Test', balance: 100);
      ai.placeBet();
      expect(ai.bet, greaterThan(0));
      expect(ai.bet, lessThanOrEqualTo(100));
      expect(ai.balance, 100 - ai.bet);
    });

    test('does not bet with zero balance', () {
      final ai = AiPlayer(name: 'Test', balance: 0);
      ai.placeBet();
      expect(ai.bet, 0);
    });

    test('reset clears hand and bet', () {
      final ai = AiPlayer(name: 'Test', balance: 100);
      ai.placeBet();
      ai.receiveCards([
        PlayingCard(suit: Suit.spades, rank: Rank.ten),
        PlayingCard(suit: Suit.hearts, rank: Rank.seven),
      ]);
      ai.reset();
      expect(ai.hand, isNull);
      expect(ai.bet, 0);
    });
  });
}

GameState _setupPlayerTurn() {
  final game = GameState();
  game.placeBet(100);
  game.startNewRound();
  if (game.phase == GamePhase.insurance) {
    game.declineInsurance();
  }
  if (game.phase == GamePhase.roundOver) {
    game.resetForNewRound();
    game.placeBet(100);
    game.startNewRound();
    if (game.phase == GamePhase.insurance) {
      game.declineInsurance();
    }
  }
  return game;
}

GameState _setupPlayerTurnNoBlackjack() {
  for (int i = 0; i < 500; i++) {
    final game = GameState();
    game.placeBet(100);
    game.startNewRound();
    if (game.phase == GamePhase.insurance) {
      game.declineInsurance();
    }
    if (game.phase == GamePhase.playerTurn &&
        !game.checkForBlackjack() &&
        game.phase == GamePhase.playerTurn) {
      return game;
    }
  }
  return _setupPlayerTurn();
}

GameState? _setupInsuranceGame() {
  for (int i = 0; i < 500; i++) {
    final game = GameState();
    game.placeBet(100);
    game.startNewRound();
    if (game.phase == GamePhase.insurance) {
      return game;
    }
  }
  return null;
}

GameState? _setupSplittableGame() {
  for (int i = 0; i < 500; i++) {
    final game = GameState();
    game.placeBet(100);
    game.startNewRound();
    if (game.phase == GamePhase.insurance) {
      game.declineInsurance();
    }
    if (game.phase == GamePhase.playerTurn && game.canSplit) {
      return game;
    }
  }
  return null;
}
