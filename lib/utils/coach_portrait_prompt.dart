import '../models/coach.dart';

/// ChatGPT·이미지 API용 감독 픽셀아트 초상 프롬프트 생성.
class CoachPortraitPrompt {
  CoachPortraitPrompt._();

  static const maxBatchSize = 5;

  static const commonRulesKo = '''
공통 규칙

- 고전 일본 축구게임(Web Soccer 2 느낌)
- 16~32bit 픽셀아트
- 5등신
- 귀엽지 않고 멋있는 SD 비율
- 얼굴 특징은 실제 감독을 참고하지만 100% 동일하지 않게 적당히 단순화
- 얼굴만 봐도 누군지 알 정도의 특징 유지
- 나이가 제시되면 해당 나이대 외형 반영
- 실사 느낌 금지
- 검은 배경
- 역동적인 포즈
- 축구공 없음
- 팀 로고 없음
- 국가 엠블럼 없음
- 브랜드 로고 없음
- 스폰서 없음
- 정장 또는 캐주얼 복장 (팀 유니폼 아님)
- 문양 최소화
- PNG
- 캐릭터 하나만 중앙 배치''';

  /// 감독 1명용 (자동화 파이프라인 등).
  static String buildSinglePrompt(Coach coach) {
    return '''
아래 규칙과 감독 목록에 맞춰 축구 감독 픽셀아트 초상 1장을 PNG로 만들어주세요.

$commonRulesKo

감독목록

1. ${_coachLine(coach)}
'''
        .trim();
  }

  /// ChatGPT 수동 배치용 — 최대 5명, 복붙 한 번.
  static String buildBatchPrompt(List<Coach> coaches) {
    if (coaches.isEmpty) {
      return '';
    }
    if (coaches.length == 1) {
      return buildSinglePrompt(coaches.first);
    }

    final buffer = StringBuffer()
      ..writeln(
        '아래 규칙과 감독 목록에 맞춰 축구 감독 픽셀아트 초상 ${coaches.length}장을 각각 PNG로 만들어주세요.',
      )
      ..writeln('1024 x 1024 사이즈 ${coaches.length}명의 감독 나열')
      ..writeln()
      ..writeln(commonRulesKo)
      ..writeln()
      ..writeln('감독목록')
      ..writeln();

    for (var i = 0; i < coaches.length; i++) {
      buffer.writeln('${i + 1}. ${_coachLine(coaches[i])}');
    }
    return buffer.toString().trimRight();
  }

  static String _coachLine(Coach coach) {
    final nationality = _orDash(coach.nationality);
    final age = _orDash(coach.age?.toString());
    final coachType = coach.coachType.trim().isNotEmpty
        ? coach.coachType.trim()
        : '-';
    final rank = coach.effectiveRank.toString();
    return '${coach.name}-$nationality-$age-$coachType-$rank';
  }

  static String _orDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }
}
