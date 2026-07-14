import '../template_models.dart';

List<CommentTemplate> buildShotTemplates() {
  return [
    const CommentTemplate(
      id: 'shot_generic_01',
      eventType: 'shot',
      text: '{time} {scorer}가 {distancePhrase} {footPhrase} 골대를 겨냥합니다.',
    ),
    const CommentTemplate(
      id: 'shot_generic_02',
      eventType: 'shot',
      text: '{time} {scorer}가{styleTone?} {distancePhrase} {footPhrase} 찬스를 노립니다.',
    ),
    const CommentTemplate(
      id: 'shot_generic_03',
      eventType: 'shot',
      text: '{time} {scorer}가 {distancePhrase} 슈팅 찬스를 잡습니다.',
    ),
    const CommentTemplate(
      id: 'shot_off_01',
      eventType: 'shot',
      text: '{time} {scorer}가 {distancePhrase} {footPhrase} 찬스를 노리지만 {shotOutcome}.',
      when: {'offTarget': true},
    ),
    const CommentTemplate(
      id: 'shot_post_01',
      eventType: 'shot_woodwork',
      text: '{time} {scorer}가 {distancePhrase} {footPhrase} 겨냥한 슈팅이 {shotOutcome}!',
      when: {'hitPost': true},
    ),
    const CommentTemplate(
      id: 'shot_wood_fallback',
      eventType: 'shot_woodwork',
      text: '{time} {scorer}가 {distancePhrase} {footPhrase} 찬 슈팅이 골대를 맞춥니다!',
    ),
    // Rarely shown on timeline; keep soft wording if used in player detail
    const CommentTemplate(
      id: 'shot_on_01',
      eventType: 'shot_on_target',
      text: '{time} {scorer}가 {distancePhrase} {footPhrase} 골문을 정확히 겨냥합니다.',
    ),
    const CommentTemplate(
      id: 'shot_on_02',
      eventType: 'shot_on_target',
      text: '{time} {scorer}가{styleTone?} {distancePhrase} 유효한 코스로 찬스를 노립니다.',
    ),
    const CommentTemplate(
      id: 'save_01',
      eventType: 'save',
      text: '{time} {shooter}가 유효슈팅을 날렸지만 {gk}의 선방으로 막힙니다.',
    ),
    const CommentTemplate(
      id: 'save_02',
      eventType: 'save',
      text: '{time} {shooter}가 유효슈팅을 날렸지만 {gk}의 걷어내기로 막힙니다.',
    ),
    const CommentTemplate(
      id: 'save_03',
      eventType: 'save',
      text: '{time} {shooter}가 유효슈팅을 날렸지만 {gk}가 몸을 날려 막아냅니다.',
    ),
    const CommentTemplate(
      id: 'save_04',
      eventType: 'save',
      text: '{time} {shooter}가 유효슈팅을 날렸지만 {gk}의 선방에 걸립니다.',
      when: {'saved': true},
    ),
  ];
}

List<CommentTemplate> buildFoulTemplates() {
  return [
    const CommentTemplate(
      id: 'foul_01',
      eventType: 'foul',
      text: '{time} {scorer}가 {victim}에게 {foulPhrase}을 범합니다.',
    ),
    const CommentTemplate(
      id: 'foul_02',
      eventType: 'foul',
      text: '{time} {scorer}가 {victim}에게 {foulTypeKo} 파울을 범합니다.',
    ),
    const CommentTemplate(
      id: 'foul_03',
      eventType: 'foul',
      text: '{time} {scorer}가 {victim}에게 {foulPhrase}을 범해 플레이를 끊습니다.',
    ),
    const CommentTemplate(
      id: 'foul_04',
      eventType: 'foul',
      text: '{time} {scorer}가 {victim}을(를) 거친 반칙으로 넘어뜨립니다.',
    ),
  ];
}

List<CommentTemplate> buildCardTemplates() {
  return [
    const CommentTemplate(
      id: 'yellow_01',
      eventType: 'yellow_card',
      text: '{time} {scorer}가 {reasonPhrase} {cardNoun}을(를) 받습니다.',
    ),
    const CommentTemplate(
      id: 'yellow_02',
      eventType: 'yellow_card',
      text: '{time} {scorer}가 {foulTypeKo} 파울로 {cardNoun} 경고를 받습니다.',
    ),
    const CommentTemplate(
      id: 'yellow_03',
      eventType: 'yellow_card',
      text: '{time} {scorer}가 {reasonPhrase} 경고를 받습니다.',
    ),
    const CommentTemplate(
      id: 'red_01',
      eventType: 'red_card',
      text: '{time} {scorer}가 {victim}을(를) 향한 파울로 {reasonPhrase} 퇴장당합니다.',
    ),
    const CommentTemplate(
      id: 'red_02',
      eventType: 'red_card',
      text: '{time} {scorer}가 {reasonPhrase} {cardNoun}을(를) 받고 퇴장합니다.',
    ),
    const CommentTemplate(
      id: 'red_03',
      eventType: 'red_card',
      text: '{time} {scorer}가 {foulTypeKo} 파울로 {reasonPhrase} 퇴장당합니다.',
    ),
    const CommentTemplate(
      id: 'red_04',
      eventType: 'red_card',
      text: '{time} {scorer}가 {reasonPhrase} 레드카드를 받고 그라운드를 떠납니다.',
    ),
  ];
}

List<CommentTemplate> buildCornerTemplates() {
  return [
    const CommentTemplate(
      id: 'corner_near_01',
      eventType: 'corner',
      text: '{time} {scorer}가 {cornerSidePhrase} 코너킥을 올립니다.',
      when: {'cornerSide': ['near']},
    ),
    const CommentTemplate(
      id: 'corner_far_01',
      eventType: 'corner',
      text: '{time} {scorer}가 {cornerSidePhrase} 코너킥을 올립니다.',
      when: {'cornerSide': ['far']},
    ),
    const CommentTemplate(
      id: 'corner_generic',
      eventType: 'corner',
      text: '{time} {scorer}가 코너킥을 올립니다.',
    ),
  ];
}

List<CommentTemplate> buildMiscTemplates() {
  return [
    const CommentTemplate(
      id: 'fk_01',
      eventType: 'free_kick',
      text: '{time} {scorer}가 프리킥을 찹니다.',
    ),
    const CommentTemplate(
      id: 'pk_01',
      eventType: 'penalty',
      text: '{time} {scorer}가 페널티 키커로 나섭니다.',
    ),
    const CommentTemplate(
      id: 'pk_goal_01',
      eventType: 'penalty_scored',
      text: '{time} {scorer}가 페널티킥을 골로 연결합니다. {score}',
    ),
    const CommentTemplate(
      id: 'pk_miss_01',
      eventType: 'penalty_missed',
      text: '{time} {scorer}가 페널티킥을 빗나갑니다.',
    ),
    const CommentTemplate(
      id: 'pk_miss_02',
      eventType: 'penalty_miss',
      text: '{time} {scorer}가 페널티킥을 빗나갑니다.',
    ),
    const CommentTemplate(
      id: 'offside_01',
      eventType: 'offside',
      text: '{time} {scorer}가 오프사이드에 걸립니다.',
    ),
    const CommentTemplate(
      id: 'sub_01',
      eventType: 'substitution',
      text: '{time} {outPlayer}가 빠지고 {inPlayer}가 투입됩니다.',
    ),
    const CommentTemplate(
      id: 'injury_01',
      eventType: 'injury',
      text: '{time} {scorer}가 부상을 입습니다.',
    ),
    const CommentTemplate(
      id: 'dribble_01',
      eventType: 'dribble',
      text: '{time} {scorer}가 드리블로 돌파합니다.',
    ),
    const CommentTemplate(
      id: 'cross_01',
      eventType: 'cross',
      text: '{time} {scorer}가 크로스를 올립니다.',
    ),
    const CommentTemplate(
      id: 'key_pass_01',
      eventType: 'key_pass',
      text: '{time} {scorer}가 결정적 패스를 찔러줍니다.',
    ),
    const CommentTemplate(
      id: 'attack_01',
      eventType: 'attack',
      text: '{time} {scorer}가 {attackBuildAction}.',
    ),
    const CommentTemplate(
      id: 'attack_build_01',
      eventType: 'attack_build',
      text: '{time} {scorer}가 {attackBuildAction}.',
    ),
    const CommentTemplate(
      id: 'attack_build_02',
      eventType: 'attack_build',
      text: '{time} {scorer}가{styleTone?} {attackBuildAction}.',
    ),
    const CommentTemplate(
      id: 'attack_build_03',
      eventType: 'attack_build',
      text: '{time} {scorer}가 {lanePhrase} {attackBuildAction}.',
    ),
    const CommentTemplate(
      id: 'ht_01',
      eventType: 'halftime',
      text: '{time} 전반이 종료됩니다. {score}',
    ),
    const CommentTemplate(
      id: 'ft_01',
      eventType: 'fulltime',
      text: '{time} 경기가 종료됩니다. {score}',
    ),
  ];
}
