import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Snake',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.amberAccent,
          background: Colors.black,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        useMaterial3: true,
      ),
      home: const MainMenu(),
      debugShowCheckedModeBanner: false,
    );
  }
}
