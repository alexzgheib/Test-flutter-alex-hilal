import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardManager {
  static const String _easyKey = 'highscore_easy';
  static const String _mediumKey = 'highscore_medium';
  static const String _hardKey = 'highscore_hard';

  static Future<int> getHighScore(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    switch (difficulty) {
      case 'Easy':
        return prefs.getInt(_easyKey) ?? 0;
      case 'Medium':
        return prefs.getInt(_mediumKey) ?? 0;
      case 'Hard':
        return prefs.getInt(_hardKey) ?? 0;
      default:
        return 0;
    }
  }

  static Future<void> saveHighScore(String difficulty, int score) async {
    final currentHighScore = await getHighScore(difficulty);
    if (score > currentHighScore) {
      final prefs = await SharedPreferences.getInstance();
      switch (difficulty) {
        case 'Easy':
          await prefs.setInt(_easyKey, score);
          break;
        case 'Medium':
          await prefs.setInt(_mediumKey, score);
          break;
        case 'Hard':
          await prefs.setInt(_hardKey, score);
          break;
      }
    }
  }
}
