import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }

class _SnakeGameState extends State<SnakeGame> with SingleTickerProviderStateMixin {
  static const int rows = 30; // 30 grid units high
  static const int columns = 20; // 20 grid units wide
  static const int initialSnakeLength = 3;

  List<Point<int>> snake = [];
  Point<int> food = const Point<int>(0, 0);
  Direction direction = Direction.right;
  bool isPlaying = false;
  int score = 0;
  Timer? gameTimer;
  Random random = Random();

  late AnimationController _wingController;
  late Animation<double> _wingAnimation;

  @override
  void initState() {
    super.initState();
    _wingController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..repeat(reverse: true);
    _wingAnimation = Tween<double>(begin: 0.2, end: 1.2).animate(
      CurvedAnimation(parent: _wingController, curve: Curves.easeInOut),
    );
    _startNewGame();
  }

  @override
  void dispose() {
    _wingController.dispose();
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
    _spawnFood();
  }

  void _startGameLoop() {
    if (isPlaying) return;
    isPlaying = true;
    gameTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
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
    setState(() {
      food = newFood;
    });
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
        _spawnFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void _checkCollision() {
    Point<int> head = snake.first;
    // Check collision with itself
    for (int i = 1; i < snake.length; i++) {
      if (head == snake[i]) {
        _gameOver();
        return;
      }
    }
  }

  void _gameOver() {
    _stopGameLoop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('Your Score: $score\n\nTap to restart.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _startNewGame();
                });
              },
              child: const Text('Restart'),
            ),
          ],
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
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  if (!isPlaying)
                    const Text(
                      'Swipe or Tap to Start',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onVerticalDragUpdate: _handleSwipe,
                onHorizontalDragUpdate: _handleSwipe,
                onTapUp: _handleTap,
                child: Container(
                  color: Colors.grey[900], // game board background
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
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Add snake
                          ...snake.asMap().entries.map((entry) {
                            int index = entry.key;
                            Point<int> p = entry.value;
                            Widget segment = Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? Colors.amberAccent // Gold head
                                    : Colors.amber,      // Gold body
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );

                            if (index == 0) {
                              double baseRotation = 0.0;
                              switch (direction) {
                                case Direction.up: baseRotation = -pi / 2; break;
                                case Direction.down: baseRotation = pi / 2; break;
                                case Direction.left: baseRotation = pi; break;
                                case Direction.right: baseRotation = 0.0; break;
                              }

                              segment = AnimatedBuilder(
                                animation: _wingAnimation,
                                builder: (context, child) {
                                  final angle = _wingAnimation.value;
                                  return Transform.rotate(
                                    angle: baseRotation,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Left/Top wing
                                        Positioned(
                                          top: -cellHeight * 0.5,
                                          child: Transform(
                                            alignment: Alignment.bottomCenter,
                                            transform: Matrix4.identity()..rotateX(angle),
                                            child: Container(
                                              width: cellWidth * 0.8,
                                              height: cellHeight * 0.8,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 4),
                                                ]
                                              ),
                                            )
                                          ),
                                        ),
                                        // Right/Bottom wing
                                        Positioned(
                                          bottom: -cellHeight * 0.5,
                                          child: Transform(
                                            alignment: Alignment.topCenter,
                                            transform: Matrix4.identity()..rotateX(-angle),
                                            child: Container(
                                              width: cellWidth * 0.8,
                                              height: cellHeight * 0.8,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                borderRadius: const BorderRadius.only(
                                                  bottomLeft: Radius.circular(10),
                                                  bottomRight: Radius.circular(10),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 4),
                                                ]
                                              ),
                                            )
                                          ),
                                        ),
                                        child!,
                                      ],
                                    ),
                                  );
                                },
                                child: segment,
                              );
                            }

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
