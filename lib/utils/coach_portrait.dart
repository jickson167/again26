/// 감독 초상화 URL. 파일명은 coach id와 동일 (예: ch_0001.png).
class CoachPortrait {
  CoachPortrait._();

  static const baseUrl = String.fromEnvironment(
    'COACH_PORTRAIT_BASE_URL',
    defaultValue: 'https://jickson167.github.io/again26/coach_images',
  );

  static String urlFor(String coachId) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/$coachId.png';
  }

  static String expectedUrl(dynamic coach) {
    final custom = coach.portraitUrl?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return urlFor(coach.id);
  }
}

class CoachPortraitPath {
  CoachPortraitPath._();

  static const storageDir = 'coach_images';
}
