import 'package:flutter/material.dart';

import '../assets/again26_title_logo.dart';

/// 게임 상단 타이틀 로고.
///
/// 이미지 교체:
/// 1) `assets/images/again26icon.png` 덮어쓰기
/// 2) `scripts/sync_title_logo.sh` 실행 (웹 파일 + 임베드 바이트 갱신)
/// 3) 앱 핫 리스타트 후 브라우저 강력 새로고침
class GameTitleLogo extends StatelessWidget {
  const GameTitleLogo({
    super.key,
    required this.size,
    this.backgroundColor = const Color(0xFF0F172A),
  });

  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Image.memory(
        again26TitleLogoBytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
