import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'audio_manager.dart';
import 'leaderboard_manager.dart';

class SnakeGame extends StatefulWidget {
  final String difficulty;

  const SnakeGame({super.key, required this.difficulty});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }
enum PowerUpType { add5, add10 }

class PowerUp {
  Point<int> position;
  PowerUpType type;
  int lifespan;
  int maxLifespan;
  PowerUp(this.position, this.type, this.lifespan) : maxLifespan = lifespan;
}

class _SnakeGameState extends State<SnakeGame> with SingleTickerProviderStateMixin {
  static const int rows = 30; // 30 grid units high
  static const int columns = 20; // 20 grid units wide
  static const int initialSnakeLength = 3;

  List<Point<int>> snake = [];
  Point<int> food = const Point<int>(0, 0);
  List<Point<int>> boobyTraps = []; // Booby traps
  PowerUp? activePowerUp;
  Direction direction = Direction.right;
  bool isPlaying = false;
  int score = 0;
  Timer? gameTimer;
  Random random = Random();
  int speedMs = 150; // Added speed variable


  @override
  void initState() {
    super.initState();
    _playMusic();
    _startNewGame();
  }

  Future<void> _playMusic() async {
    await AudioManager.playBgm();
  }

  @override
  void dispose() {
    AudioManager.stopBgm();
    super.dispose();
  }

  void _startNewGame() {
    snake.clear();
    // Start snake in the middle
    int startY = rows ~/ 2;
    int startX = columns ~/ 2;
    for (int i = 0; i < initialSnakeLength; i++) {
      snake.add(Point<int>(startX - i, startY));
    }
    direction = Direction.right;
    score = 0;
    activePowerUp = null;
    boobyTraps.clear();
    _spawnFood();
  }

  void _startGameLoop() {
    if (isPlaying) return;
    isPlaying = true;
    
    speedMs = 150;
    if (widget.difficulty == 'Easy') speedMs = 200;
    if (widget.difficulty == 'Hard') speedMs = 100;

    gameTimer = Timer.periodic(Duration(milliseconds: speedMs), (timer) {
      if (activePowerUp != null) {
        setState(() {
          activePowerUp!.lifespan--;
          if (activePowerUp!.lifespan <= 0) {
            activePowerUp = null;
          }
        });
      }
      _moveSnake();
      _checkCollision();
    });
  }

  void _stopGameLoop() {
    isPlaying = false;
    gameTimer?.cancel();
  }

  void _spawnFood() {
    Point<int> newFood;
    do {
      newFood = Point<int>(random.nextInt(columns), random.nextInt(rows));
    } while (snake.contains(newFood));
      food = newFood;
      // Spawn booby traps based on difficulty and score
      int trapChance = score > 10 ? 20 : 5; // Spawn chance depending on score
      if (random.nextInt(100) < trapChance) {
        Point<int> p;
        do {
          p = Point<int>(random.nextInt(columns), random.nextInt(rows));
        } while (snake.contains(p) || p == food || (activePowerUp != null && p == activePowerUp!.position) || boobyTraps.contains(p));
        boobyTraps.add(p);
      }

      // 15% chance to spawn a powerup if none exists
      if (activePowerUp == null && random.nextDouble() < 0.15) {
        Point<int> p;
        do {
          p = Point<int>(random.nextInt(columns), random.nextInt(rows));
        } while (snake.contains(p) || p == food || boobyTraps.contains(p));
        // Randomly pick powerup type
        PowerUpType type = random.nextBool() ? PowerUpType.add5 : PowerUpType.add10;
        activePowerUp = PowerUp(p, type, 50); // Lifespan of 50 ticks
      }
  }

  void _moveSnake() {
    setState(() {
      Point<int> head = snake.first;
      Point<int> newHead;

      switch (direction) {
        case Direction.up:
          newHead = Point<int>(head.x, head.y - 1);
          break;
        case Direction.down:
          newHead = Point<int>(head.x, head.y + 1);
          break;
        case Direction.left:
          newHead = Point<int>(head.x - 1, head.y);
          break;
        case Direction.right:
          newHead = Point<int>(head.x + 1, head.y);
          break;
      }

      // Walkthrough walls logic
      if (newHead.x < 0) {
        newHead = Point<int>(columns - 1, newHead.y);
      } else if (newHead.x >= columns) {
        newHead = Point<int>(0, newHead.y);
      } else if (newHead.y < 0) {
        newHead = Point<int>(newHead.x, rows - 1);
      } else if (newHead.y >= rows) {
        newHead = Point<int>(newHead.x, 0);
      }

      snake.insert(0, newHead);

      if (newHead == food) {
        score++;
        AudioManager.playEatSound();
        _spawnFood();
      } else {
        snake.removeLast();
      }

      // Check powerup eating
      if (activePowerUp != null && newHead == activePowerUp!.position) {
        AudioManager.playPowerupSound();
        switch (activePowerUp!.type) {
          case PowerUpType.add5:
            score += 5;
            break;
          case PowerUpType.add10:
            score += 10;
            break;
        }
        activePowerUp = null;
      }
    });
  }

  void _checkCollision() {
    Point<int> head = snake.first;
    // Check collision with itself
    for (int i = 1; i < snake.length; i++) {
      if (head == snake[i]) {
        _gameOver(false);
        return;
      }
    }
    // Check collision with booby traps
    if (boobyTraps.contains(head)) {
      _gameOver(true);
      return;
    }
  }

  void _gameOver(bool causedByTrap) {
    _stopGameLoop();
    if (causedByTrap) {
      AudioManager.playExplosionSound();
    } else {
      AudioManager.playGameOverSound();
    }
    AudioManager.stopBgm();
    LeaderboardManager.saveHighScore(widget.difficulty, score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.redAccent,
                  blurRadius: 20,
                  spreadRadius: -5,
                )
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GAME OVER',
                  style: GoogleFonts.pressStart2p(
                    color: Colors.redAccent,
                    fontSize: 24,
                  ),
                ).animate().shake(duration: 400.ms),
                const SizedBox(height: 20),
                Text(
                  'Difficulty: ${widget.difficulty}\nScore: $score',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Back to Main Menu
                      },
                      child: const Text('MAIN MENU'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _startNewGame();
                          _playMusic();
                        });
                      },
                      child: const Text('RESTART'),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
        );
      },
    );
  }

  void _handleSwipe(DragUpdateDetails details) {
    if (!isPlaying) {
      _startGameLoop();
    }
    double dx = details.delta.dx;
    double dy = details.delta.dy;

    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      if (dx > 0 && direction != Direction.left) {
        direction = Direction.right;
      } else if (dx < 0 && direction != Direction.right) {
        direction = Direction.left;
      }
    } else {
      // Vertical swipe
      if (dy > 0 && direction != Direction.up) {
        direction = Direction.down;
      } else if (dy < 0 && direction != Direction.down) {
        direction = Direction.up;
      }
    }
  }

  void _handleTap(TapUpDetails details) {
    if (!isPlaying) {
      _startGameLoop();
    }

    // Tap quadrants strategy: left half = turn left/right, right half = turn right/up, etc.
    // Given the request "touch controls", we can map regions logically based on center
    // or we can allow quadrant tapping. Let's map quadrants relative to screen center.
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final localPos = details.localPosition;
      final dx = localPos.dx - size.width / 2;
      final dy = localPos.dy - size.height / 2;

      // if tap is strictly closer to top/bottom edges or left/right edges
      if (dx.abs() > dy.abs()) {
        // Tap is predominantly horizontal
        if (dx > 0 && direction != Direction.left) {
          direction = Direction.right;
        } else if (dx < 0 && direction != Direction.right) {
          direction = Direction.left;
        }
      } else {
        // Tap is predominantly vertical
        if (dy > 0 && direction != Direction.up) {
          direction = Direction.down;
        } else if (dy < 0 && direction != Direction.down) {
          direction = Direction.up;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      AudioManager.isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white54,
                    ),
                    onPressed: () async {
                      await AudioManager.toggleMute();
                      setState(() {});
                    },
                  ),
                  Text(
                    'SCORE: $score',
                    style: GoogleFonts.pressStart2p(color: Colors.greenAccent, fontSize: 16),
                  ),
                  if (activePowerUp != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              activePowerUp!.type == PowerUpType.add10 ? '+10 POWERUP!' : '+5 POWERUP!',
                              style: GoogleFonts.pressStart2p(
                                color: activePowerUp!.type == PowerUpType.add10 ? Colors.purpleAccent : Colors.yellowAccent,
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: activePowerUp!.lifespan / activePowerUp!.maxLifespan,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                activePowerUp!.type == PowerUpType.add10 ? Colors.purpleAccent : Colors.yellowAccent
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!isPlaying)
                    Text(
                      'TAP TO START',
                      style: GoogleFonts.pressStart2p(color: Colors.amber, fontSize: 12),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onVerticalDragUpdate: _handleSwipe,
                onHorizontalDragUpdate: _handleSwipe,
                onTapUp: _handleTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                    ]
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double cellWidth = constraints.maxWidth / columns;
                      final double cellHeight = constraints.maxHeight / rows;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Add food
                          Positioned(
                            left: food.x * cellWidth,
                            top: food.y * cellHeight,
                            width: cellWidth,
                            height: cellHeight,
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.redAccent,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1, duration: 400.ms),
                          ),
                          // Add Powerup
                          if (activePowerUp != null)
                            Positioned(
                              left: activePowerUp!.position.x * cellWidth,
                              top: activePowerUp!.position.y * cellHeight,
                              width: cellWidth,
                              height: cellHeight,
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: activePowerUp!.type == PowerUpType.add10
                                      ? Colors.purpleAccent
                                      : Colors.yellowAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: activePowerUp!.type == PowerUpType.add10
                                          ? Colors.purpleAccent
                                          : Colors.yellowAccent,
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.2, duration: 300.ms),
                            ),
                          // Add Booby Traps
                          ...boobyTraps.map((trap) => Positioned(
                            left: trap.x * cellWidth,
                            top: trap.y * cellHeight,
                            width: cellWidth,
                            height: cellHeight,
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orangeAccent,
                                    blurRadius: 5,
                                  )
                                ],
                              ),
                              child: const Center(
                                child: Text('💀', style: TextStyle(fontSize: 10)),
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).shake(hz: 8, curve: Curves.easeInOut),
                          )),
                          // Add snake
                          ...snake.asMap().entries.map((entry) {
                            int index = entry.key;
                            Point<int> p = entry.value;
                            Widget segment = Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: index == 0
                                        ? Colors.cyanAccent // Neon head
                                        : Colors.cyan,      // Neon body
                                borderRadius: BorderRadius.circular(index == 0 ? 8 : 4),
                                boxShadow: index == 0 ? const [
                                  BoxShadow(
                                    color: Colors.cyanAccent,
                                    blurRadius: 10,
                                  )
                                ] : null,
                              ),
                            );

                            return Positioned(
                              left: p.x * cellWidth,
                              top: p.y * cellHeight,
                              width: cellWidth,
                              height: cellHeight,
                              child: segment,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
