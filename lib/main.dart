import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MediaJournalApp());
}

class MediaJournalApp extends StatelessWidget {
  const MediaJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absolute Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0A2463), // Deep Navy
        scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Cool light grey-blue for contrast
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0A2463),
          secondary: Color(0xFFFF6B00), // True vibrant Orange
          tertiary: Color(0xFFFFC300),  // Golden Yellow
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF0A2463),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF0A2463), fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}