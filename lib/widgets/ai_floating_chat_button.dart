import 'package:flutter/material.dart';
import '../screens/category_chat_screen.dart';

class AIFloatingChatButton extends StatelessWidget {
  final String categoryTitle;
  final String categoryContent;
  final List<Map<String, dynamic>> kpiData;

  const AIFloatingChatButton({
    super.key,
    required this.categoryTitle,
    required this.categoryContent,
    required this.kpiData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.all(8),
      child: Material(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryChatScreen(
                  categoryTitle: categoryTitle,
                  categoryContent: categoryContent,
                  kpiData: kpiData,
                ),
              ),
            );
          },
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5c258d),
                  Color(0xFF4389A2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
