import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'pneumonia_classifier_page.dart';
import 'fruits_classifier_page.dart';
import 'chatbot_page.dart';
import 'tflite_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize TFLite Web if running on web
  if (kIsWeb) {
    try {
      await TFLiteHelper.initialize();
    } catch (e) {
      print('Warning: Could not initialize TFLite Web: $e');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart App - AppControle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/pneumonia': (context) => const PneumoniaClassifierPage(),
        '/fruits': (context) => const FruitsClassifierPage(),
        '/chatbot': (context) => const ChatbotPage(),
      },
    );
  }
}
