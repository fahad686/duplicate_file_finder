import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const DuplicateFileFinderApp());
}

class DuplicateFileFinderApp extends StatelessWidget {
  const DuplicateFileFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duplicate File Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1724),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A9EFF),
          surface: Color(0xFF1A2538),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
