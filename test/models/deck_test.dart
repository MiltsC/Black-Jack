import 'package:flutter_test/flutter_test.dart';
import 'package:blackjack/models/deck.dart';

void main() {
  group('Deck', () {
    test('starts with 52 cards', () {
      final deck = Deck();
      expect(deck.remaining, 52);
    });

    test('deal removes a card', () {
      final deck = Deck();
      deck.deal();
      expect(deck.remaining, 51);
    });

    test('dealt card is face up by default', () {
      final deck = Deck();
      final card = deck.deal();
      expect(card.faceUp, true);
    });

    test('dealt card can be face down', () {
      final deck = Deck();
      final card = deck.deal(faceUp: false);
      expect(card.faceUp, false);
    });

    test('dealing all 52 cards empties deck', () {
      final deck = Deck();
      for (int i = 0; i < 52; i++) {
        deck.deal();
      }
      expect(deck.remaining, 0);
    });

    test('dealing from empty deck rebuilds it', () {
      final deck = Deck();
      for (int i = 0; i < 52; i++) {
        deck.deal();
      }
      final card = deck.deal();
      expect(card, isNotNull);
      expect(deck.remaining, 51);
    });

    test('shuffle does not change card count', () {
      final deck = Deck();
      deck.shuffle();
      expect(deck.remaining, 52);
    });

    test('shuffle changes card order (probabilistic)', () {
      final deck1 = Deck();
      final deck2 = Deck();
      deck2.shuffle();

      final cards1 = <String>[];
      final cards2 = <String>[];
      for (int i = 0; i < 10; i++) {
        cards1.add('${deck1.deal().rankLabel}${deck1.deal().suitSymbol}');
        cards2.add('${deck2.deal().rankLabel}${deck2.deal().suitSymbol}');
      }
      expect(cards1, isNot(equals(cards2)));
    });
  });
}
