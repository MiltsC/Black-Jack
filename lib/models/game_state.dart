import 'dart:math';
import 'playing_card.dart';
import 'deck.dart';

enum GamePhase { betting, insurance, playerTurn, dealerTurn, roundOver }

enum RoundResult { playerWins, dealerWins, tie, playerBlackjack, playerBust, dealerBust }

class PlayerHand {
  final List<PlayingCard> cards;
  int bet;
  bool isStanding;
  bool isDoubled;
  RoundResult? result;
  int payout;
  final bool fromSplit;

  PlayerHand({required this.cards, required this.bet, this.fromSplit = false})
      : isStanding = false,
        isDoubled = false,
        payout = 0;

  int get handValue {
    int value = 0;
    int aces = 0;
    for (final card in cards) {
      value += card.value;
      if (card.rank == Rank.ace) aces++;
    }
    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }
    return value;
  }

  bool get isBusted => handValue > 21;
  bool get isBlackjack => !fromSplit && cards.length == 2 && handValue == 21;
}

class GameState {
  final Deck deck = Deck();
  List<PlayingCard> dealerHand = [];
  List<PlayerHand> hands = [];
  int activeHandIndex = 0;
  GamePhase phase = GamePhase.betting;

  int balance = 1000;
  int currentBet = 0;
  int totalPayout = 0;
  int insuranceBet = 0;
  bool insuranceTaken = false;

  GameState() {
    deck.shuffle();
  }

  // -- Convenience getters --

  PlayerHand get activeHand => hands[activeHandIndex];
  bool get isSplit => hands.length > 1;
  bool get canBet => phase == GamePhase.betting && balance > 0;
  bool get isBroke => balance <= 0 && phase == GamePhase.betting;

  bool get dealerShowsAce =>
      dealerHand.isNotEmpty && dealerHand[0].faceUp && dealerHand[0].rank == Rank.ace;

  int get insuranceCost => (currentBet / 2).ceil();

  bool get canInsure => phase == GamePhase.insurance && balance >= insuranceCost;

  int get dealerHandValue => _fullValue(dealerHand);

  int get dealerVisibleValue {
    int value = 0;
    int aces = 0;
    for (final card in dealerHand) {
      if (!card.faceUp) continue;
      value += card.value;
      if (card.rank == Rank.ace) aces++;
    }
    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }
    return value;
  }

  static int _fullValue(List<PlayingCard> cards) {
    int value = 0;
    int aces = 0;
    for (final card in cards) {
      value += card.value;
      if (card.rank == Rank.ace) aces++;
    }
    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }
    return value;
  }

  // -- Legal move checks --

  bool get canSplit =>
      phase == GamePhase.playerTurn &&
      hands.length < 2 &&
      activeHand.cards.length == 2 &&
      activeHand.cards[0].value == activeHand.cards[1].value &&
      balance >= activeHand.bet;

  bool get canDoubleDown =>
      phase == GamePhase.playerTurn &&
      activeHand.cards.length == 2 &&
      !activeHand.isDoubled &&
      balance >= activeHand.bet;

  // -- Actions --

  bool placeBet(int amount) {
    if (amount > balance || amount <= 0) return false;
    currentBet = amount;
    balance -= amount;
    return true;
  }

  void startNewRound() {
    dealerHand.clear();
    hands.clear();
    activeHandIndex = 0;
    totalPayout = 0;
    insuranceBet = 0;
    insuranceTaken = false;

    if (deck.remaining < 15) {
      deck.shuffle();
    }

    hands.add(PlayerHand(cards: [deck.deal(), deck.deal()], bet: currentBet));
    dealerHand.add(deck.deal());
    dealerHand.add(deck.deal(faceUp: false));

    if (dealerShowsAce) {
      phase = GamePhase.insurance;
    } else {
      phase = GamePhase.playerTurn;
    }
  }

  void acceptInsurance() {
    if (phase != GamePhase.insurance) return;
    insuranceBet = insuranceCost;
    balance -= insuranceBet;
    insuranceTaken = true;
    phase = GamePhase.playerTurn;
  }

  void declineInsurance() {
    if (phase != GamePhase.insurance) return;
    insuranceBet = 0;
    insuranceTaken = false;
    phase = GamePhase.playerTurn;
  }

  /// Returns true if the round ended immediately (dealer or player blackjack).
  bool checkForBlackjack() {
    final dealerBJ = dealerHandValue == 21;
    final playerBJ = activeHand.isBlackjack;

    if (dealerBJ) {
      revealDealerCards();
      if (playerBJ) {
        activeHand.result = RoundResult.tie;
      } else {
        activeHand.result = RoundResult.dealerWins;
      }
      _settleBets();
      phase = GamePhase.roundOver;
      return true;
    }

    if (playerBJ) {
      revealDealerCards();
      activeHand.result = RoundResult.playerBlackjack;
      _settleBets();
      phase = GamePhase.roundOver;
      return true;
    }

    return false;
  }

  /// Returns true if the active hand can still be played.
  bool hit() {
    if (phase != GamePhase.playerTurn) return false;

    activeHand.cards.add(deck.deal());

    if (activeHand.isBusted) {
      activeHand.result = RoundResult.playerBust;
      _advanceHand();
      return false;
    }

    if (activeHand.handValue == 21) {
      activeHand.isStanding = true;
      _advanceHand();
      return false;
    }

    return true;
  }

  void stand() {
    if (phase != GamePhase.playerTurn) return;
    activeHand.isStanding = true;
    _advanceHand();
  }

  void doubleDown() {
    if (!canDoubleDown) return;

    balance -= activeHand.bet;
    activeHand.bet *= 2;
    activeHand.isDoubled = true;
    activeHand.cards.add(deck.deal());

    if (activeHand.isBusted) {
      activeHand.result = RoundResult.playerBust;
    } else {
      activeHand.isStanding = true;
    }

    _advanceHand();
  }

  void split() {
    if (!canSplit) return;

    final card1 = activeHand.cards[0];
    final card2 = activeHand.cards[1];
    final bet = activeHand.bet;

    balance -= bet;

    hands.clear();
    hands.add(PlayerHand(cards: [card1, deck.deal()], bet: bet, fromSplit: true));
    hands.add(PlayerHand(cards: [card2, deck.deal()], bet: bet, fromSplit: true));

    activeHandIndex = 0;

    if (card1.rank == Rank.ace) {
      hands[0].isStanding = true;
      hands[1].isStanding = true;
      _startDealerTurn();
    }
  }

  // -- Internal --

  void _advanceHand() {
    if (isSplit && activeHandIndex < hands.length - 1) {
      activeHandIndex++;
      return;
    }
    _startDealerTurn();
  }

  void _startDealerTurn() {
    if (hands.every((h) => h.isBusted)) {
      revealDealerCards();
      _settleBets();
      phase = GamePhase.roundOver;
      return;
    }

    phase = GamePhase.dealerTurn;
    revealDealerCards();
    _dealerPlay();
  }

  void revealDealerCards() {
    for (final card in dealerHand) {
      card.faceUp = true;
    }
  }

  bool _isDealerSoft17() {
    if (dealerHandValue != 17) return false;
    int value = 0;
    int aces = 0;
    for (final card in dealerHand) {
      value += card.value;
      if (card.rank == Rank.ace) aces++;
    }
    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }
    return aces > 0;
  }

  void _dealerPlay() {
    int safety = 10;
    while ((dealerHandValue < 17 || _isDealerSoft17()) && safety-- > 0) {
      dealerHand.add(deck.deal());
    }

    for (final hand in hands) {
      if (hand.isBusted) continue;

      if (dealerHandValue > 21) {
        hand.result = RoundResult.dealerBust;
      } else if (dealerHandValue > hand.handValue) {
        hand.result = RoundResult.dealerWins;
      } else if (hand.handValue > dealerHandValue) {
        hand.result = RoundResult.playerWins;
      } else {
        hand.result = RoundResult.tie;
      }
    }

    _settleBets();
    phase = GamePhase.roundOver;
  }

  void _settleBets() {
    totalPayout = 0;

    if (insuranceTaken) {
      final dealerBJ = dealerHandValue == 21 && dealerHand.length == 2;
      if (dealerBJ) {
        final insurancePayout = insuranceBet * 3;
        balance += insurancePayout;
        totalPayout += insurancePayout;
      }
    }

    for (final hand in hands) {
      switch (hand.result) {
        case RoundResult.playerBlackjack:
          hand.payout = (hand.bet * 2.5).round();
          break;
        case RoundResult.playerWins:
        case RoundResult.dealerBust:
          hand.payout = hand.bet * 2;
          break;
        case RoundResult.tie:
          hand.payout = hand.bet;
          break;
        default:
          hand.payout = 0;
          break;
      }
      balance += hand.payout;
      totalPayout += hand.payout;
    }
  }

  int get totalBetAmount => hands.fold(0, (sum, h) => sum + h.bet);

  void resetForNewRound() {
    currentBet = 0;
    insuranceBet = 0;
    insuranceTaken = false;
    phase = GamePhase.betting;
  }

  String resultMessageForHand(PlayerHand hand) {
    switch (hand.result) {
      case RoundResult.playerBlackjack:
        return 'BLACKJACK!';
      case RoundResult.playerWins:
        return 'Win!';
      case RoundResult.dealerWins:
        return 'Dealer wins';
      case RoundResult.playerBust:
        return 'Bust!';
      case RoundResult.dealerBust:
        return 'Dealer busts!';
      case RoundResult.tie:
        return 'Push';
      default:
        return '';
    }
  }

  String get payoutMessage {
    final totalBets = totalBetAmount;
    final net = totalPayout - totalBets;
    if (net > 0) return '+\$$net';
    if (net < 0) return '-\$${net.abs()}';
    return '\$$totalBets returned';
  }

  bool get isNetWin => totalPayout > totalBetAmount;
  bool get isNetLoss => totalPayout < totalBetAmount;
}

class AiPlayer {
  final String name;
  int balance;
  PlayerHand? hand;
  RoundResult? result;
  int bet = 0;
  final Random _rng = Random();

  AiPlayer({required this.name, this.balance = 1000});

  void placeBet() {
    if (balance <= 0) {
      bet = 0;
      return;
    }
    final options = [10, 25, 50, 100].where((b) => b <= balance).toList();
    if (options.isEmpty) {
      bet = balance;
    } else {
      bet = options[_rng.nextInt(options.length)];
    }
    balance -= bet;
  }

  void receiveCards(List<PlayingCard> cards) {
    hand = PlayerHand(cards: cards, bet: bet);
  }

  void play(Deck deck) {
    if (hand == null || bet == 0) return;
    int safety = 10;
    while (hand!.handValue < 17 && !hand!.isBusted && safety-- > 0) {
      hand!.cards.add(deck.deal());
    }
    if (hand!.isBusted) {
      hand!.result = RoundResult.playerBust;
    }
    hand!.isStanding = true;
  }

  void settle(int dealerValue) {
    if (hand == null || bet == 0) return;

    if (hand!.isBusted) {
      hand!.payout = 0;
    } else if (hand!.isBlackjack && hand!.cards.length == 2) {
      hand!.payout = (bet * 2.5).round();
      hand!.result = RoundResult.playerBlackjack;
    } else if (dealerValue > 21) {
      hand!.payout = bet * 2;
      hand!.result = RoundResult.dealerBust;
    } else if (hand!.handValue > dealerValue) {
      hand!.payout = bet * 2;
      hand!.result = RoundResult.playerWins;
    } else if (hand!.handValue == dealerValue) {
      hand!.payout = bet;
      hand!.result = RoundResult.tie;
    } else {
      hand!.payout = 0;
      hand!.result = RoundResult.dealerWins;
    }

    balance += hand!.payout;
  }

  void reset() {
    hand = null;
    result = null;
    bet = 0;
  }
}
