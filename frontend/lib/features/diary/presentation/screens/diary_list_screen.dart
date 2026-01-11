import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiaryListScreen extends StatelessWidget {
  const DiaryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diaries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // TODO: Navigate to calendar view
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No diaries yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start writing your first diary entry!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scan button
          FloatingActionButton.small(
            heroTag: 'scan',
            onPressed: () => context.go('/diaries/camera'),
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 8),
          // Manual entry button
          FloatingActionButton.extended(
            heroTag: 'manual',
            onPressed: () => context.go('/diaries/new'),
            icon: const Icon(Icons.edit),
            label: const Text('Write'),
          ),
        ],
      ),
    );
  }
}
