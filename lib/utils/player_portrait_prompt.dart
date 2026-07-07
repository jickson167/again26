import '../models/player.dart';
import 'player_portrait.dart';

/// ChatGPT·이미지 API용 선수 픽셀아rt 초상 프롬프트 생성.
///
/// 규칙: 선수 1명 = PNG 1장 = `{id}.png` (투명 배경, 캐릭터만).
class PlayerPortraitPrompt {
  PlayerPortraitPrompt._();

  static const maxBatchSize = 5;

  /// API·ChatGPT — 선수 1명.
  static const englishCoreSingle =
      'Create exactly one transparent-background PNG character sprite for this one player only. '
      'Do not create multiple characters. No ball, no number, no logo, no emblem, no sponsor, no armband.';

  /// API·ChatGPT — 수동 배치(최대 5명, PNG 각각).
  static const englishCoreBatch =
      'Create separate transparent-background PNG character sprites — exactly one PNG per player listed below. '
      'Do not combine multiple characters into one image or one sprite sheet. '
      'No ball, no number, no logo, no emblem, no sponsor, no armband.';

  static const commonRulesKo = '''
공통 규칙

- 선수 1명 = 이미지 1장 (여러 명 한 장 금지, 스프라이트 시트 금지)
- 투명 배경 PNG (알파 채널) — 캐릭터만, 배경색·그라데이션 없음
- 고전 일본 축구게임(Web Soccer 2 느낌)
- 16~32bit 픽셀아rt
- 5등신, 귀엽지 않고 멋있는 SD 비율
- 얼굴은 실제 선수 특징을 참고하되 실사처럼 닮지 않게 단순화
- 얼굴만 봐도 누군지 알 정도의 특징 유지
- 포지션에 맞는 역동적인 자세
- 캐릭터 1명만 화면 중앙 배치 (일정한 크기·여백·중심축 유지)
- 축구공 없음
- 등번호 없음
- 팀 로고 없음
- 국가 엠블럼 없음
- 브랜드 로고 없음
- 스폰서 없음
- 팔 완장 없음
- 유니폼 문양 최소화 — 시드/소속팀 색감만 참고
- 저장: `{id}.png`''';

  static String playerLine(Player player) {
    final nationality = _orDash(player.nationality);
    final age = _orDash(player.ageStage);
    final position = player.detailPosition?.trim().isNotEmpty == true
        ? player.detailPosition!.trim()
        : player.position.label;
    final seed = player.displaySeedNames.join('; ');
    final rank = player.rank?.toString() ?? '-';

    return '${player.name}-$nationality-$age-$position-$seed-$rank';
  }

  static String uniformNote(Player player) {
    final seeds = player.displaySeedNames;
    final isGeneralOnly =
        seeds.length == 1 && seeds.first == Player.defaultSeedName;
    if (isGeneralOnly) {
      return '일반시드 — 현재 소속팀 유니폼 색감만 참고, 매우 심플하게';
    }
    return '특정시드(${seeds.join(', ')}) — 해당 시드의 대표 유니폼 색상만 참고';
  }

  /// 선수 1명용 (자동화 파이프라인 등).
  static String buildSinglePrompt(Player player) {
    return '''
$englishCoreSingle

$commonRulesKo

선수 정보
- id: ${player.id}
- name: ${player.name}
- nationality: ${_orDash(player.nationality)}
- age: ${_orDash(player.ageStage)}
- detail_position: ${player.detailPosition?.trim().isNotEmpty == true ? player.detailPosition!.trim() : player.position.label}
- seed_name: ${player.displaySeedNames.join('; ')}
- rank: ${player.rank?.toString() ?? '-'}

한 줄 요약: ${playerLine(player)}

유니폼: ${uniformNote(player)}
포즈: ${player.detailPosition ?? player.position.label} 포지션에 어울리는 역동적인 자세

출력
- 파일명: ${player.id}.png
- 투명 배경 PNG, 캐릭터 1명만 중앙 배치
- 로컬 저장: ${PlayerPortraitPath.localPathForId(player.id)}
- DB portrait_url: ${PlayerPortraitPath.urlForId(player.id)}
'''
        .trim();
  }

  /// ChatGPT 수동 배치용 — 최대 5명, 복붙 한 번.
  static String buildBatchPrompt(List<Player> players) {
    if (players.isEmpty) {
      return '';
    }
    if (players.length == 1) {
      return buildSinglePrompt(players.first);
    }

    final buffer = StringBuffer()
      ..writeln(
        '아래 ${players.length}명 각각 PNG 1장씩 만들어주세요. '
        '한 장에 여러 명 넣지 마세요. ChatGPT에서 5장 따로 받아 '
        '${PlayerPortraitPath.storageDir}/{{id}}.png 로 저장합니다.',
      )
      ..writeln()
      ..writeln(englishCoreBatch)
      ..writeln()
      ..writeln(commonRulesKo)
      ..writeln()
      ..writeln('선수목록 (형식: 이름-국적-나이-포지션-시드이름-랭크)')
      ..writeln();

    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      buffer
        ..writeln('${i + 1}. ${playerLine(player)}')
        ..writeln('   id: ${player.id} → ${player.id}.png')
        ..writeln('   유니폼: ${uniformNote(player)}')
        ..writeln(
          '   포즈: ${player.detailPosition ?? player.position.label}에 맞는 역동적 자세',
        )
        ..writeln();
    }

    buffer.writeln(
      '각 선수마다 투명 배경 PNG 1장, 캐릭터만 중앙. '
      '파일명은 반드시 id와 동일 (${players.map((p) => '${p.id}.png').join(', ')}).',
    );
    return buffer.toString().trimRight();
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
