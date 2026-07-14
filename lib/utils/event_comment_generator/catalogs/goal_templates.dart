import '../template_models.dart';

/// Goal templates — Korean order: who → where/how → what.
List<CommentTemplate> buildGoalTemplates() {
  final t = <CommentTemplate>[];

  void add(
    String id,
    String text, {
    Map<String, Object?> when = const {},
    double weight = 1.0,
  }) {
    t.add(CommentTemplate(
      id: id,
      eventType: 'goal',
      text: text,
      when: when,
      weight: weight,
    ));
  }

  // A: solo box finish
  add('goal_solo_box_01',
      '{time} {intensity}! {scorer}가{styleTone?} {distancePhrase} {footPhrase} {shotVerb} 골망을 흔듭니다. {score}');
  add('goal_solo_box_02',
      '{time} {scorer}가 {distancePhrase} {footPhrase} {shotVerb} 단독으로 마무리합니다. {score}');
  add('goal_solo_box_03',
      '{time} {intensity}! {scorer}가 {distancePhrase} {connector} 골을 넣습니다. {reaction}. {score}');
  add('goal_solo_box_04',
      '{time} {scorer}가 {distancePhrase} {shotVerb} 기회를 놓치지 않고 득점합니다. {score}');
  add('goal_solo_box_05',
      '{time} {scorer}가 문전 혼전 속에서 {shotVerb} 골을 넣습니다. {score}',
      when: {'distance': ['inside_box'], 'requireAssist': false});
  add('goal_solo_box_06',
      '{time} {scorer}가 {distancePhrase} {footPhrase} {shotVerb} 혼자 해결합니다. {score}',
      when: {'requireAssist': false, 'distance': ['inside_box']});
  add('goal_solo_box_07',
      '{time} {intensity}! {scorer}가 {distancePhrase} {shotVerb} 단독 골을 기록합니다. {score}',
      when: {'requireAssist': false, 'shotType': ['tapin', 'placement']});
  add('goal_solo_box_08',
      '{time} {scorer}가 박스 안에서 침착하게 밀어 넣습니다. {score}',
      when: {'requireAssist': false, 'distance': ['inside_box'], 'shotType': ['tapin', 'placement']});

  // B: solo mid/long
  add('goal_solo_range_01',
      '{time} {intensity}! {scorer}가 {distancePhrase} {shotVerb} 원더골을 터뜨립니다. {score}',
      when: {'requireAssist': false, 'distance': ['outside_box', 'long_range']});
  add('goal_solo_range_02',
      '{time} {scorer}가 {distancePhrase} {footPhrase} 강하게 때려 넣습니다. {score}',
      when: {'requireAssist': false, 'distance': ['outside_box', 'long_range'], 'shotType': ['power', 'curler']});
  add('goal_solo_range_03',
      '{time} {scorer}가 {distancePhrase} {shotVerb} 장거리 슈팅을 골로 연결합니다. {score}',
      when: {'requireAssist': false, 'distance': ['long_range']});
  add('goal_solo_range_04',
      '{time} {scorer}가 {distancePhrase} 감아차기로 골문을 가릅니다. {score}',
      when: {'requireAssist': false, 'shotType': ['curler']});
  add('goal_solo_range_05',
      '{time} {scorer}가 {distancePhrase} 과감하게 감아 차 넣습니다. {reaction}. {score}',
      when: {'requireAssist': false, 'shotType': ['curler', 'power']});
  add('goal_solo_range_06',
      '{time} {intensity}! {scorer}가 {distancePhrase} {footPhrase} 중거리 골을 터뜨립니다. {score}',
      when: {'requireAssist': false, 'distance': ['outside_box']});
  add('goal_solo_range_07',
      '{time} {scorer}가 {distancePhrase} 한 방으로 승부를 바꿉니다. {score}',
      when: {'requireAssist': false, 'distance': ['outside_box', 'long_range']});
  add('goal_solo_range_08',
      '{time} {scorer}가 {distancePhrase} 키퍼가 미처 반응하기 전에 슈팅을 꽂아 넣습니다. {score}',
      when: {'requireAssist': false, 'distance': ['outside_box', 'long_range']});

  // C: through assist
  add('goal_through_01',
      '{time} {intensity}! {scorer}가 {assist}의 {assistLead}를 받아 {shotVerb} 득점합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['through']});
  add('goal_through_02',
      '{time} {scorer}가 {assist}가 찌른 패스를 받아 {oneOnOnePhrase} 마무리합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['through']});
  add('goal_through_03',
      '{time} {scorer}가 {assist}의 킬러 패스를 받아 골을 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['through']});
  add('goal_through_04',
      '{time} {scorer}가{styleTone?} {assist}의 스루패스를 {connector} 골로 연결합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['through']});
  add('goal_through_05',
      '{time} {scorer}가 {assist}의 패스를 받아 {oneOnOnePhrase} 침착하게 밀어 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['through'], 'oneOnOne': true});
  add('goal_through_06',
      '{time} {scorer}가 {assist}의 침투 패스를 받아 {distancePhrase} 골을 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['through']});
  add('goal_through_07',
      '{time} {scorer}가 수비 라인을 깨는 패스를 받아 득점합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['through']});
  add('goal_through_08',
      '{time} {intensity}! {scorer}가 {assist}의 {assistLead}를 받아 {shotVerb} 골을 기록합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['through']});

  // D: cross header
  add('goal_cross_header_01',
      '{time} {intensity}! {scorer}가 {assist}의 {assistLead}를 {headerVerb} 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cross', 'corner'], 'shotType': ['header']});
  add('goal_cross_header_02',
      '{time} {scorer}가 {assist}의 측면 크로스를 헤딩으로 골로 연결합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cross'], 'shotType': ['header']});
  add('goal_cross_header_03',
      '{time} {scorer}가 {assist}의 크로스를 받아 헤딩으로 골문 구석을 찌릅니다. {score}',
      when: {'requireAssist': true, 'shotType': ['header']});
  add('goal_cross_header_04',
      '{time} {scorer}가 {assist}가 올린 공을 머리로 받아내며 득점합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cross', 'corner'], 'shotType': ['header']});
  add('goal_cross_header_05',
      '{time} {intensity}! {scorer}가{styleTone?} 공중볼을 제압한 뒤 헤딩골을 넣습니다. {score}',
      when: {'shotType': ['header']});
  add('goal_cross_header_06',
      '{time} {scorer}가 {distancePhrase} 정확한 헤더로 골을 넣습니다. {score}',
      when: {'shotType': ['header'], 'distance': ['inside_box']});
  add('goal_cross_header_07',
      '{time} {scorer}가 {assist}의 크로스를 다이빙 헤딩으로 마무리합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cross'], 'shotType': ['header']});
  add('goal_cross_header_08',
      '{time} {scorer}가 제공권 싸움에서 이긴 뒤 헤딩으로 득점합니다. {score}',
      when: {'shotType': ['header']});

  // E: cutback tapin
  add('goal_cutback_01',
      '{time} {intensity}! {scorer}가 {assist}의 {assistLead}를 받아 탭인으로 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cutback'], 'shotType': ['tapin', 'placement']});
  add('goal_cutback_02',
      '{time} {scorer}가 컷백을 받아 쉽게 밀어 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cutback']});
  add('goal_cutback_03',
      '{time} {scorer}가 {assist}가 뒤로 빼준 공을 빈 골대에 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cutback']});
  add('goal_cutback_04',
      '{time} {scorer}가 컷백을 받아 {connector} 마무리합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cutback']});
  add('goal_cutback_05',
      '{time} {scorer}가 문전에서 컷백을 받아 골을 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cutback'], 'distance': ['inside_box']});
  add('goal_cutback_06',
      '{time} {scorer}가 {assist}의 센스 있는 컷백을 놓치지 않고 득점합니다. {score}',
      when: {'requireAssist': true, 'assistType': ['cutback']});

  // F: after dribble
  add('goal_dribble_01',
      '{time} {intensity}! {scorer}가 {dribblePhrase} {shotVerb} 골을 넣습니다. {score}',
      when: {'afterDribble': true});
  add('goal_dribble_02',
      '{time} {scorer}가 수비 {defendersBeaten}명을 제친 뒤 개인기로 득점합니다. {score}',
      when: {'afterDribble': true, 'minDefendersBeaten': 1});
  add('goal_dribble_03',
      '{time} {scorer}가{styleTone?} {dribblePhrase} {footPhrase} 마무리합니다. {score}',
      when: {'afterDribble': true});
  add('goal_dribble_04',
      '{time} {scorer}가 드리블 돌파 끝에 골을 넣습니다. {reaction}. {score}',
      when: {'afterDribble': true});
  add('goal_dribble_05',
      '{time} {scorer}가 상대를 따돌린 뒤 {distancePhrase} 슈팅으로 골을 넣습니다. {score}',
      when: {'afterDribble': true});
  add('goal_dribble_06',
      '{time} {intensity}! {scorer}가 개인 돌파 끝에 골을 넣습니다. {score}',
      when: {'afterDribble': true, 'minDefendersBeaten': 2});
  add('goal_dribble_07',
      '{time} {scorer}가 현란한 드리블 후 {shotVerb} 골망을 가릅니다. {score}',
      when: {'afterDribble': true});
  add('goal_dribble_08',
      '{time} {scorer}가 수비를 농락한 뒤 골을 넣습니다. {score}',
      when: {'afterDribble': true});

  // G: one on one
  add('goal_121_01',
      '{time} {intensity}! {scorer}가 {oneOnOnePhrase} {shotVerb} 득점합니다. {score}',
      when: {'oneOnOne': true});
  add('goal_121_02',
      '{time} {scorer}가 {oneOnOnePhrase} 침착하게 마무리합니다. {score}',
      when: {'oneOnOne': true});
  add('goal_121_03',
      '{time} {scorer}가 키퍼와 마주한 뒤 칩샷으로 골을 넣습니다. {score}',
      when: {'oneOnOne': true, 'shotType': ['chip']});
  add('goal_121_04',
      '{time} {scorer}가 일대일에서 키퍼를 제치고 넣습니다. {score}',
      when: {'oneOnOne': true});
  add('goal_121_05',
      '{time} {intensity}! {scorer}가 단독 찬스를 살려 골을 넣습니다. {score}',
      when: {'oneOnOne': true});
  add('goal_121_06',
      '{time} {scorer}가{styleTone?} {oneOnOnePhrase} 구석을 찔러 넣습니다. {score}',
      when: {'oneOnOne': true, 'shotType': ['placement', 'chip']});

  // H: counter
  add('goal_counter_01',
      '{time} {intensity}! {scorer}가 {counterPhrase} 골을 넣습니다. {score}',
      when: {'counterAttack': true});
  add('goal_counter_02',
      '{time} {scorer}가{styleTone?} 빠른 역습 상황에서 {shotVerb} 골을 넣습니다. {score}',
      when: {'counterAttack': true});
  add('goal_counter_03',
      '{time} {scorer}가 {counterPhrase} {assist}의 패스를 받아 마무리합니다. {score}',
      when: {'counterAttack': true, 'requireAssist': true});
  add('goal_counter_04',
      '{time} {scorer}가 카운터어택 끝에 골을 넣습니다. {reaction}. {score}',
      when: {'counterAttack': true});
  add('goal_counter_05',
      '{time} {scorer}가 역습의 선두에서 득점합니다. {score}',
      when: {'counterAttack': true});
  add('goal_counter_06',
      '{time} {intensity}! {scorer}가 전환 공격 끝에 골을 넣습니다. {score}',
      when: {'counterAttack': true});

  // I: keeper touched
  add('goal_keeper_01',
      '{time} {intensity}! {scorer}가 {distancePhrase} 찬 슈팅이 {keeperTouchPhrase} 들어갑니다. {score}',
      when: {'keeperTouched': true});
  add('goal_keeper_02',
      '{time} {scorer}가 키퍼 손끝을 스치게 한 슈팅으로 그대로 골을 넣습니다. {score}',
      when: {'keeperTouched': true});
  add('goal_keeper_03',
      '{time} {scorer}가 {keeperTouchPhrase} 기어이 골망을 흔듭니다. {score}',
      when: {'keeperTouched': true});
  add('goal_keeper_04',
      '{time} {scorer}가 선방을 뚫고 결국 골을 넣습니다. {score}',
      when: {'keeperTouched': true});
  add('goal_keeper_05',
      '{time} {intensity}! {scorer}가 {keeperTouchPhrase} 득점에 성공합니다. {score}',
      when: {'keeperTouched': true});

  // J: foot / special shot types
  add('goal_foot_left_01',
      '{time} {intensity}! {scorer}가 {distancePhrase} 왼발 슈팅으로 골문을 가릅니다. {score}',
      when: {'foot': ['left']});
  add('goal_foot_right_01',
      '{time} {scorer}가 {distancePhrase} 오른발로 강하게 때려 넣습니다. {score}',
      when: {'foot': ['right']});
  add('goal_volley_01',
      '{time} {intensity}! {scorer}가 {distancePhrase} {shotVerb} 발리슛을 골로 만듭니다. {score}',
      when: {'shotType': ['volley']});
  add('goal_volley_02',
      '{time} {scorer}가 공중볼을 받아쳐 발리골을 넣습니다. {score}',
      when: {'shotType': ['volley']});
  add('goal_chip_01',
      '{time} {scorer}가 {distancePhrase} 절묘한 칩샷으로 골을 넣습니다. {score}',
      when: {'shotType': ['chip']});
  add('goal_chip_02',
      '{time} {intensity}! {scorer}가 키퍼 머리 너머로 칩골을 넣습니다. {score}',
      when: {'shotType': ['chip']});
  add('goal_outside_01',
      '{time} {scorer}가 {distancePhrase} 아웃사이드로 감아 차 넣습니다. {score}',
      when: {'shotType': ['outside_foot']});
  add('goal_outside_02',
      '{time} {intensity}! {scorer}가 아웃풋으로 원더골을 터뜨립니다. {score}',
      when: {'shotType': ['outside_foot']});
  add('goal_power_01',
      '{time} {scorer}가 {distancePhrase} 강슈로 골망을 찢습니다. {score}',
      when: {'shotType': ['power']});
  add('goal_rebound_01',
      '{time} {scorer}가 {assist}에게서 나온 {assistLead}를 밀어 넣습니다. {score}',
      when: {'requireAssist': true, 'assistType': ['rebound']});

  // Generic fallbacks
  add('goal_generic_01',
      '{time} {intensity}! {scorer}가 {distancePhrase} 득점합니다. {score}',
      weight: 0.4);
  add('goal_generic_02',
      '{time} 골! {scorer}가{styleTone?} {distancePhrase} {shotVerb} 골을 넣습니다. {score}',
      weight: 0.5);
  add('goal_generic_03',
      '{time} {scorer}가 {distancePhrase} 골을 넣습니다. {reaction}. {score}',
      weight: 0.4);
  add('goal_generic_assist',
      '{time} {intensity}! {scorer}가 {assist}의 도움을 받아 골을 넣습니다. {score}',
      when: {'requireAssist': true},
      weight: 0.45);

  return t;
}
