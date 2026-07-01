enum PlayerPosition {
  fw('fw', '공격수'),
  mf('mf', '미드필더'),
  df('df', '수비수'),
  gk('gk', '골키퍼');

  const PlayerPosition(this.code, this.label);

  final String code;
  final String label;

  static PlayerPosition fromCode(String? value) {
    return PlayerPosition.values.firstWhere(
      (position) => position.code == value,
      orElse: () => PlayerPosition.mf,
    );
  }
}
