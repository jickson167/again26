import '../models/player.dart';

/// 선수 초상화 URL. 파일명은 player id와 동일 (예: 0001.png).
class PlayerPortrait {
  PlayerPortrait._();

  static const baseUrl = String.fromEnvironment(
    'PORTRAIT_BASE_URL',
    defaultValue: 'https://jickson167.github.io/again26/player_images',
  );

  static String urlFor(String playerId) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/$playerId.png';
  }

  static String expectedUrl(Player player) {
    final custom = player.portraitUrl?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return urlFor(player.id);
  }
}
