import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';

class StorageService {
  static const _balanceKey = 'blackjack_balance';
  static const _statsKey = 'blackjack_stats';
  static const _helpShownKey = 'blackjack_help_shown';

  static Future<void> saveBalance(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, balance);
  }

  static Future<int> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? 1000;
  }

  static Future<void> saveStats(GameStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, stats.serialize());
  }

  static Future<GameStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_statsKey);
    if (data == null) return GameStats();
    return GameStats.deserialize(data);
  }

  static Future<bool> hasSeenHelp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_helpShownKey) ?? false;
  }

  static Future<void> markHelpSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_helpShownKey, true);
  }
}
