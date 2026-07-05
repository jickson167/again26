import 'package:flutter/material.dart';

class EmbedWebPage extends StatelessWidget {
  const EmbedWebPage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('선수 생성기는 웹 브라우저에서만 사용할 수 있습니다.\n$url'),
      ),
    );
  }
}
