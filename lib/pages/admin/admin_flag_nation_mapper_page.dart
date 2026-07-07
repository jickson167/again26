import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_web_paths.dart';
import '../../widgets/embed_web_page.dart';

class AdminFlagNationMapperPage extends StatelessWidget {
  const AdminFlagNationMapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    final url = flagNationMapperPageUrl();

    return Scaffold(
      appBar: AppBar(
        title: const Text('국기 ↔ 나라 매핑'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin'),
            icon: const Icon(Icons.flag),
            label: const Text('매니저 관리'),
          ),
        ],
      ),
      body: EmbedWebPage(url: url),
    );
  }
}
