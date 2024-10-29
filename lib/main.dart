import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/home_screen.dart';
import 'services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AIService.loadChatHistories(); // Load chat histories
  canLaunchUrl(Uri.parse('https://www.example.com')); // This line ensures the plugin is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(title: 'Medical Dashboard'),
    );
  }
}
