import '../models/player.dart';
import 'player_portrait.dart';

/// ChatGPT·이미지 API용 선수 픽셀아rt 초상 프롬프트 생성.
class PlayerPortraitPrompt {
  PlayerPortraitPrompt._();

  static const maxBatchSize = 6;

  static const commonRulesKo = '''
공통 규칙

- 고전 일본 축구게임(Web Soccer 2 느낌)
- 16~32bit 픽셀아트
- 5등신
- 귀엽지 않고 멋있는 SD 비율
- 얼굴 특징은 실제 선수를 참고하지만 100% 동일하지 않게 적당히 단순화
- 얼굴만 봐도 누군지 알 정도의 특징 유지
- 실사 느낌 금지
- 검은 배경
- 역동적인 포즈
- 축구공 없음
- 등번호 없음
- 팀 로고 없음
- 국가 엠블럼 없음
- 브랜드 로고 없음
- 스폰서 없음
- 팔 완장 없음
- 유니폼 문양 최소화
- 일반시드면 현재 소속팀 유니폼 색감만 참고하고 매우 심플하게 제작
- 특정시드면 해당 시드의 대표 유니폼 색상만 참고
- PNG
- 캐릭터 하나만 중앙 배치''';

  /// 선수 1명용 (자동화 파이프라인 등).
  static String buildSinglePrompt(Player player) {
    return '''
아래 규칙과 선수 목록에 맞춰 축구 선수 픽셀아트 초상 1장을 PNG로 만들어주세요.

$commonRulesKo

선수목록

1. ${_playerLine(player)}
'''
        .trim();
  }

  /// ChatGPT 수동 배치용 — 최대 6명, 복붙 한 번.
  static String buildBatchPrompt(List<Player> players) {
    if (players.isEmpty) {
      return '';
    }
    if (players.length == 1) {
      return buildSinglePrompt(players.first);
    }

    final buffer = StringBuffer()
      ..writeln(
        '아래 규칙과 선수 목록에 맞춰 축구 선수 픽셀아트 초상 ${players.length}장을 각각 PNG로 만들어주세요.',
      )
      ..writeln('1024 x 1024 사이즈 6명의 선수 나열')
      ..writeln()
      ..writeln(commonRulesKo)
      ..writeln()
      ..writeln('선수목록')
      ..writeln();

    for (var i = 0; i < players.length; i++) {
      buffer.writeln('${i + 1}. ${_playerLine(players[i])}');
    }
    return buffer.toString().trimRight();
  }

  static String _playerLine(Player player) {
    final nationality = _orDash(player.nationality);
    final age = _orDash(player.ageStage);
    final position = player.detailPosition?.trim().isNotEmpty == true
        ? player.detailPosition!.trim()
        : player.position.label;
    final seed = player.displaySeedNames.join('; ');
    final rank = player.rank?.toString() ?? '-';
    return '${player.name}-$nationality-$age-$position-$seed-$rank';
  }

  static String _orDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }
}

/// DB·파일 경로 규칙 (현재 스키마: portrait_url).
class PlayerPortraitPath {
  PlayerPortraitPath._();

  static const storageDir = 'web/player_images';

  static String fileNameForId(String playerId) => '$playerId.png';

  static String localPathForId(String playerId) =>
      '$storageDir/${fileNameForId(playerId)}';

  static String urlForId(String playerId) {
    final base = PlayerPortrait.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/${fileNameForId(playerId)}';
  }
}
