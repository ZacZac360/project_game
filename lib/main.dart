import 'package:flutter/material.dart';
import 'game_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAWG Game Explorer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850], // Custom gray for AppBar
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system, // Auto-switch based on system settings
      home: const GameListScreen(),
    );
  }
}
