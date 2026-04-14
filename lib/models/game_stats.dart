import 'dart:convert';

class GameStats {
  int handsPlayed = 0;
  int handsWon = 0;
  int handsLost = 0;
  int handsPushed = 0;
  int blackjacks = 0;
  int currentStreak = 0;
  int bestStreak = 0;
  int biggestWin = 0;
  int biggestLoss = 0;
  int peakBalance = 1000;

  double get winRate => handsPlayed == 0 ? 0 : handsWon / handsPlayed;

  void recordWin(int payout) {
    handsPlayed++;
    handsWon++;
    currentStreak = currentStreak >= 0 ? currentStreak + 1 : 1;
    if (currentStreak > bestStreak) bestStreak = currentStreak;
    if (payout > biggestWin) biggestWin = payout;
  }

  void recordBlackjack(int payout) {
    blackjacks++;
    recordWin(payout);
  }

  void recordLoss(int lostAmount) {
    handsPlayed++;
    handsLost++;
    currentStreak = currentStreak <= 0 ? currentStreak - 1 : -1;
    if (lostAmount > biggestLoss) biggestLoss = lostAmount;
  }

  void recordPush() {
    handsPlayed++;
    handsPushed++;
    currentStreak = 0;
  }

  void updatePeakBalance(int balance) {
    if (balance > peakBalance) peakBalance = balance;
  }

  Map<String, dynamic> toJson() => {
        'handsPlayed': handsPlayed,
        'handsWon': handsWon,
        'handsLost': handsLost,
        'handsPushed': handsPushed,
        'blackjacks': blackjacks,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'biggestWin': biggestWin,
        'biggestLoss': biggestLoss,
        'peakBalance': peakBalance,
      };

  static GameStats fromJson(Map<String, dynamic> json) {
    final stats = GameStats();
    stats.handsPlayed = json['handsPlayed'] ?? 0;
    stats.handsWon = json['handsWon'] ?? 0;
    stats.handsLost = json['handsLost'] ?? 0;
    stats.handsPushed = json['handsPushed'] ?? 0;
    stats.blackjacks = json['blackjacks'] ?? 0;
    stats.currentStreak = json['currentStreak'] ?? 0;
    stats.bestStreak = json['bestStreak'] ?? 0;
    stats.biggestWin = json['biggestWin'] ?? 0;
    stats.biggestLoss = json['biggestLoss'] ?? 0;
    stats.peakBalance = json['peakBalance'] ?? 1000;
    return stats;
  }

  String serialize() => jsonEncode(toJson());

  static GameStats deserialize(String data) {
    try {
      return fromJson(jsonDecode(data));
    } catch (_) {
      return GameStats();
    }
  }
}
