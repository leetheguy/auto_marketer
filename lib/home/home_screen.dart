import 'package:flutter/material.dart';
import '../common/list_provider.dart'; // Import the new provider
import '../common/list_screen.dart'; // Import the new screen
import 'nav_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Marketer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            HomeNavButton(
              icon: Icons.article_outlined,
              label: 'Articles',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ListScreen(contentType: ContentType.article),
                  ),
                );
              },
            ),
            HomeNavButton(
              icon: Icons.lightbulb_outline,
              label: 'Ideas',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ListScreen(contentType: ContentType.idea),
                  ),
                );
              },
            ),
            HomeNavButton(
              icon: Icons.task_alt,
              label: 'Tasks',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ListScreen(contentType: ContentType.task),
                  ),
                );
              },
            ),
            HomeNavButton(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              onTap: () {
                // Navigate to the chat screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
