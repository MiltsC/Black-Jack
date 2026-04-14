import 'package:flutter_test/flutter_test.dart';
import 'package:blackjack/models/playing_card.dart';

void main() {
  group('PlayingCard', () {
    test('ace has value 11', () {
      final card = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      expect(card.value, 11);
    });

    test('face cards have value 10', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.jack).value, 10);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.queen).value, 10);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.king).value, 10);
    });

    test('number cards have correct values', () {
      expect(PlayingCard(suit: Suit.clubs, rank: Rank.two).value, 2);
      expect(PlayingCard(suit: Suit.clubs, rank: Rank.five).value, 5);
      expect(PlayingCard(suit: Suit.clubs, rank: Rank.ten).value, 10);
    });

    test('rank labels are correct', () {
      expect(PlayingCard(suit: Suit.spades, rank: Rank.ace).rankLabel, 'A');
      expect(PlayingCard(suit: Suit.spades, rank: Rank.king).rankLabel, 'K');
      expect(PlayingCard(suit: Suit.spades, rank: Rank.ten).rankLabel, '10');
      expect(PlayingCard(suit: Suit.spades, rank: Rank.two).rankLabel, '2');
    });

    test('suit symbols are correct', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).suitSymbol, '♥');
      expect(PlayingCard(suit: Suit.diamonds, rank: Rank.ace).suitSymbol, '♦');
      expect(PlayingCard(suit: Suit.clubs, rank: Rank.ace).suitSymbol, '♣');
      expect(PlayingCard(suit: Suit.spades, rank: Rank.ace).suitSymbol, '♠');
    });

    test('isRed returns true for hearts and diamonds', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).isRed, true);
      expect(PlayingCard(suit: Suit.diamonds, rank: Rank.ace).isRed, true);
      expect(PlayingCard(suit: Suit.clubs, rank: Rank.ace).isRed, false);
      expect(PlayingCard(suit: Suit.spades, rank: Rank.ace).isRed, false);
    });

    test('faceUp defaults to true', () {
      final card = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      expect(card.faceUp, true);
    });

    test('faceUp can be set to false', () {
      final card = PlayingCard(suit: Suit.spades, rank: Rank.ace, faceUp: false);
      expect(card.faceUp, false);
    });

    test('each card has a unique id', () {
      final a = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      final b = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      expect(a.id, isNot(b.id));
    });
  });
}
