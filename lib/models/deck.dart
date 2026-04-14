import 'playing_card.dart';

class Deck {
  final List<PlayingCard> _cards = [];

  Deck() {
    _buildDeck();
  }

  void _buildDeck() {
    _cards.clear();
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        _cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
  }

  void shuffle() {
    _cards.shuffle();
  }

  PlayingCard deal({bool faceUp = true}) {
    if (_cards.isEmpty) {
      _buildDeck();
      shuffle();
    }
    final card = _cards.removeLast();
    card.faceUp = faceUp;
    return card;
  }

  int get remaining => _cards.length;
}
