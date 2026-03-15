import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'snake_game.dart';
import 'leaderboard_manager.dart';
import 'audio_manager.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  String _selectedDifficulty = 'Medium';
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _playMenuAudio();
  }

  Future<void> _playMenuAudio() async {
    await AudioManager.playMenuBgm();
  }

  Future<void> _loadHighScore() async {
    final score = await LeaderboardManager.getHighScore(_selectedDifficulty);
    setState(() {
      _highScore = score;
    });
  }

  void _onDifficultyChanged(String? newDifficulty) {
    if (newDifficulty != null) {
      setState(() {
        _selectedDifficulty = newDifficulty;
        // Animation reset isn't strictly necessary with setState here but will trigger build
      });
      _loadHighScore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sleek dark mode
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'NEON\nSNAKE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bungeeHairline(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    shadows: [
                      const Shadow(
                        blurRadius: 10.0,
                        color: Colors.greenAccent,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 800.ms)
                  .scale(delay: 200.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 50),

                // High Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'HIGH SCORE',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_highScore',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 24,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ).animate(target: _highScore > 0 ? 1 : 0) // Basic entry anim
                  .slideY(begin: 0.5, end: 0, duration: 400.ms, curve: Curves.easeOut)
                  .fadeIn(),

                const SizedBox(height: 40),

                // Difficulty Selector
                Text(
                  'DIFFICULTY',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white54,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _selectedDifficulty,
                  dropdownColor: const Color(0xFF203A43),
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: Container(
                    height: 2,
                    color: Colors.greenAccent,
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
                  onChanged: _onDifficultyChanged,
                  items: <String>['Easy', 'Medium', 'Hard']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ).animate()
                  .fadeIn(delay: 400.ms),

                const SizedBox(height: 60),

                // Play Button
                ElevatedButton(
                  onPressed: () async {
                    await AudioManager.stopBgm(); // Stop menu music
                    // Navigate to Game
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SnakeGame(difficulty: _selectedDifficulty),
                      ),
                    );
                    // Refresh high score and music when coming back
                    _loadHighScore();
                    _playMenuAudio();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                    shadowColor: Colors.greenAccent.withOpacity(0.5),
                  ),
                  child: Text(
                    'PLAY',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 20,
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(end: 1.05, duration: 1.seconds, curve: Curves.easeInOut),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
