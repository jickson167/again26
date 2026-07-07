import 'package:flutter/material.dart';

/// 관리자 화면 모바일·좁은 화면 레이아웃.
class AdminLayout {
  AdminLayout._();

  static const compactBreakpoint = 640.0;
  static const stackedBreakpoint = 720.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static EdgeInsets dialogInsets(BuildContext context) =>
      isCompact(context) ? const EdgeInsets.all(8) : const EdgeInsets.all(16);

  static BoxConstraints dialogConstraints(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (isCompact(context)) {
      return BoxConstraints(
        maxWidth: size.width,
        maxHeight: size.height * 0.94,
      );
    }
    return const BoxConstraints(maxWidth: 960, maxHeight: 820);
  }
}
