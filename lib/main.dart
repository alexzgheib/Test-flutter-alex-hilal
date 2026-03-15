import 'package:flutter/material.dart';
import 'snake_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Snake Game (Hot Reloaded)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SnakeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}
