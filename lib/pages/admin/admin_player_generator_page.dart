import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_web_paths.dart';
import '../../widgets/embed_web_page.dart';

class AdminPlayerGeneratorPage extends StatelessWidget {
  const AdminPlayerGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final url = playerGeneratorPageUrl();

    return Scaffold(
      appBar: AppBar(
        title: const Text('선수 생성기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin'),
            icon: const Icon(Icons.person),
            label: const Text('선수 목록'),
          ),
        ],
      ),
      body: EmbedWebPage(url: url),
    );
  }
}
