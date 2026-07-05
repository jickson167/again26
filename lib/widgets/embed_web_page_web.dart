import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class EmbedWebPage extends StatefulWidget {
  const EmbedWebPage({super.key, required this.url});

  final String url;

  @override
  State<EmbedWebPage> createState() => _EmbedWebPageState();
}

class _EmbedWebPageState extends State<EmbedWebPage> {
  static int _nextViewId = 0;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'again26-embed-${_nextViewId++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      return html.IFrameElement()
        ..src = widget.url
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
