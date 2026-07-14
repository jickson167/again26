import 'seeded_random.dart';

/// Word banks for template slots. Goal-related entries alone exceed 100.
class DictionaryBank {
  DictionaryBank._();

  static const intensity = [
    '골',
    '들어갔습니다',
    '망치골',
    '결정타',
    '쐐기골',
    '동점골',
    '역전골',
    '선제골',
    '환상적인 골',
    '멋진 골',
    '귀중한 골',
    '완벽한 마무리',
  ];

  static const reaction = [
    '관중이 일어섭니다',
    '벤치가 환호합니다',
    '경기장이 술렁입니다',
    '선수들이 몰려듭니다',
    '세레머니가 이어집니다',
    '공기가 달아오릅니다',
    '함성이 터집니다',
    '해설석도 흥분합니다',
  ];

  static const connector = [
    '이어서',
    '곧바로',
    '순간적으로',
    '침착하게',
    '과감하게',
    '날카롭게',
    '재빠르게',
    '여유 있게',
  ];

  static const Map<String, List<String>> shotVerb = {
    'power': [
      '강력한 슈팅으로',
      '강슈로',
      '힘을 실은 슈팅으로',
      '폭발적인 슈팅으로',
      '묵직한 슈팅으로',
    ],
    'placement': [
      '정확한 슈팅으로',
      '구석을 노린 슈팅으로',
      '침착한 마무리로',
      '정교한 슈팅으로',
      '코너를 찌르는 슈팅으로',
    ],
    'curler': [
      '감아 찬 슈팅으로',
      '휘어지는 슈팅으로',
      '인사이드로 감아차며',
      '궤적을 그린 슈팅으로',
    ],
    'chip': [
      '칩샷으로',
      '떠올리는 슈팅으로',
      '키퍼 머리 너머로',
      '절묘한 칩으로',
    ],
    'volley': [
      '발리슛으로',
      '공중볼을 받아치며',
      '원터치 발리로',
      '시원한 발리로',
    ],
    'header': [
      '헤딩으로',
      '머리로 밀어 넣으며',
      '정확한 헤더로',
      '헤딩슛으로',
    ],
    'tapin': [
      '가볍게 밀어 넣어',
      '탭인으로',
      '원터치로 밀어 넣어',
      '간단한 마무리로',
    ],
    'outside_foot': [
      '아웃사이드 슈팅으로',
      '아웃풋으로',
      '바깥발로 감아차며',
    ],
  };

  static const Map<String, List<String>> footPhrase = {
    'left': [
      '왼발로',
    ],
    'right': [
      '오른발로',
    ],
  };

  static const Map<String, List<String>> distancePhrase = {
    'inside_box': [
      '페널티 박스 안에서',
      '문전에서',
      '골문 앞에서',
      '박스 중앙에서',
      '근접 거리에서',
    ],
    'outside_box': [
      '박스 바깥에서',
      '중거리에서',
      '페널티 아크 근처에서',
      '박스 가장자리에서',
    ],
    'long_range': [
      '먼 거리에서',
      '장거리에서',
      '하프라인 근처에서',
      '과감한 장거리 슈팅으로',
    ],
  };

  static const Map<String, List<String>> assistLead = {
    'through': [
      '스루패스',
      '킬러 패스',
      '침투 패스',
      '결정적 스루볼',
      '공간 패스',
    ],
    'cross': [
      '크로스',
      '날카로운 크로스',
      '측면 크로스',
      '올려준 공',
      '정확한 크로스',
    ],
    'cutback': [
      '컷백',
      '뒤로 빼주는 패스',
      '컷백 패스',
      '문전 컷백',
    ],
    'rebound': [
      '리바운드',
      '튕겨 나온 볼',
      '세컨드 볼',
      '흘러나온 공',
    ],
    'corner': [
      '코너킥',
      '코너 킥 볼',
      '코너에서 올라온 공',
    ],
    'freekick': [
      '프리킥',
      '프리킥 세트피스',
      'FK 볼',
    ],
  };

  static const Map<String, List<String>> foulPhrase = {
    'hold': ['홀딩 파울', '옷을 잡아끄는 파울', '붙잡는 파울'],
    'push': ['미는 파울', '푸시 파울', '등을 미는 파울'],
    'late_tackle': ['늦은 태클', '뒤늦은 태클', '타이밍이 늦은 태클'],
    'sliding': ['슬라이딩 태클 파울', '과감한 슬라이딩 파울', '거친 슬라이딩'],
    'trip': ['발을 거는 파울', '트립 파울', '발목을 거는 파울'],
    'handball': ['핸드볼', '손 반칙', '팔로 볼을 막는 반칙'],
    'dangerous_play': ['위험한 플레이', '상대를 위협하는 플레이', '위험한 동작'],
  };

  static const Map<String, List<String>> reasonPhrase = {
    'foul_accumulation': [
      '반복된 파울로',
      '파울이 거듭된 끝에',
      '지속적인 반칙으로',
    ],
    'serious_foul': [
      '심한 파울로',
      '거친 반칙으로',
      '위험한 태클로',
    ],
    'dissent': [
      '항의로',
      '판정 항의로',
      '언행 문제로',
    ],
    'professional_foul': [
      '프로페셔널 파울로',
      '결정적 찬스를 끊는 파울로',
      '전술적 파울로',
    ],
    'second_yellow': [
      '두 번째 경고로',
      '경고 누적으로',
      '연속 경고로',
    ],
    'violent_conduct': [
      '폭력적 행위로',
      '과격한 행동으로',
      '폭력 행위로',
    ],
  };

  static const Map<String, List<String>> styleTone = {
    'finisher': ['냉정하게', '결정적으로', '골잡이답게'],
    'poacher': ['문전에서 재빠르게', '침투하듯', '냄새를 맡은 듯'],
    'dribbler': ['현란한 돌파 끝에', '드리블로 풀어낸 뒤', '개인기로'],
    'counter_attacker': ['역습의 선두에서', '빠른 역습 상황에서', '카운터로'],
    'target_man': ['타겟맨답게', '몸싸움을 이겨내며', '제공권을 잡고'],
    'playmaker': ['절묘한 감각으로', '플레이메이커답게'],
    'creative_midfielder': ['창의적인 터치로', '상상력을 담아'],
    'speed_winger': ['스피드를 앞세워', '측면을 찢으며'],
    'technical': ['테크니컬하게', '섬세한 터치로'],
    'physical': ['피지컬을 앞세워', '힘으로'],
    'pressing': ['압박 끝에', '집요한 압박 후'],
    'setpiece': ['세트피스 감각으로'],
    'aerial_defender': ['공중볼 경합에서'],
    'shot_stopper': ['선방 본능으로'],
  };

  /// attack_build action phrases by player style id.
  static const Map<String, List<String>> attackBuildByStyle = {
    'speed': [
      '빠르게 드리블로 중원을 치고 나갑니다',
      '스피드를 앞세워 전방으로 질주합니다',
      '빠른 발로 공간을 헤집고 올라갑니다',
    ],
    'speed_winger': [
      '측면을 전광석화처럼 파고듭니다',
      '윙에서 속도를 살며 수비 뒤로 칩니다',
      '빠르게 사이드 라인을 타고 올라갑니다',
    ],
    'dribbler': [
      '현란한 드리블로 중원을 돌파합니다',
      '개인기로 상대를 제치며 전진합니다',
      '볼을 발에 붙인 채 수비 사이를 뚫습니다',
    ],
    'technical': [
      '섬세한 터치로 빌드업을 이어갑니다',
      '테크니컬한 패스로 전방을 엽니다',
      '짧은 패스를 주고받으며 상대를 흔듭니다',
    ],
    'playmaker': [
      '정확한 패스로 공격 방향을 바꿉니다',
      '플레이메이커답게 킬 패스 각을 만듭니다',
      '중원에서 볼을 배급하며 공격을 설계합니다',
    ],
    'creative_midfielder': [
      '예상 못 한 패스로 수비 라인을 흔듭니다',
      '창의적인 전환 패스로 전개를 엽니다',
      '한 박자 빠른 패스로 공간을 만듭니다',
    ],
    'deep_lying_playmaker': [
      '후방에서 길게 전개를 시작합니다',
      '깊은 위치에서 정확한 롱패스를 뿌립니다',
      '빌드업의 시발점이 되어 전방을 겨냥합니다',
    ],
    'tempo_controller': [
      '템포를 조절하며 공격을 쌓아 올립니다',
      '침착하게 패스 각을 만들며 전진합니다',
      '경기 호흡을 맞춰 중원을 장악합니다',
    ],
    'box_to_box': [
      '박스 투 박스로 중원을 누비며 올라갑니다',
      '왕성한 활동량으로 전방 가담합니다',
      '공수 연결을 책임지며 전진합니다',
    ],
    'physical': [
      '몸싸움을 이겨내며 볼을 전진시킵니다',
      '피지컬로 상대를 제압하고 올라갑니다',
      '힘으로 중원 경합을 이겨냅니다',
    ],
    'pressing': [
      '압박으로 볼을 뺏은 뒤 바로 전진합니다',
      '전방 압박에 이은 빠른 전개로 올라갑니다',
      '집요한 압박 후 공격으로 전환합니다',
    ],
    'pressing_forward': [
      '최전방에서 압박해 볼을 뺏고 밀어붙입니다',
      '수비수를 압박하며 공간을 엽니다',
    ],
    'pressing_midfielder': [
      '중원 압박으로 볼을 회수해 전진합니다',
      '상대 볼을 뺏어내며 공격을 잇습니다',
    ],
    'counter_attacker': [
      '역습 신호와 함께 전방으로 질주합니다',
      '카운터 타이밍에 맞춰 중원을 돌파합니다',
      '빠른 전환 공격의 선두에 섭니다',
    ],
    'inside_forward': [
      '측면에서 안쪽으로 파고들며 전진합니다',
      '인사이드 포워드답게 중앙으로 침투합니다',
    ],
    'finisher': [
      '골 찬스를 노리며 박스 쪽으로 파고듭니다',
      '결정력을 의식해 슈팅 각을 찾아 올라갑니다',
    ],
    'poacher': [
      '문전 침투를 노리며 수비 사이로 파고듭니다',
      '재빠른 움직임으로 공격 위치를 잡습니다',
    ],
    'target_man': [
      '타겟맨으로 볼을 받아내며 공격을 붙입니다',
      '몸싸움을 버티며 동료를 끌어올립니다',
    ],
    'attacking_fullback': [
      '풀백이 오버래핑하며 측면을 열어젖힙니다',
      '공격적으로 올라와 크로스를 준비합니다',
    ],
    'ball_winner': [
      '볼을 뺏어낸 뒤 과감하게 전방으로 연결합니다',
      '중원에서 커팅한 볼로 공격을 시작합니다',
    ],
    'stamina': [
      '지치지 않는 활동량으로 전방 가담을 이어갑니다',
      '넓은 활동 반경으로 공격을 지원합니다',
    ],
    'balanced': [
      '균형 잡힌 패스로 공격을 차분히 올립니다',
      '안정적으로 빌드업을 이어갑니다',
    ],
    'leader': [
      '동료를 독려하며 공격 템포를 끌어올립니다',
      '지휘하듯 패스 방향을 제시하며 전진합니다',
    ],
    'tactical': [
      '전술적으로 공간을 활용해 전개합니다',
      '위치 선정으로 패스 길을 열며 올라갑니다',
    ],
  };

  static const attackBuildByLane = {
    'left': [
      '왼쪽 측면으로 볼을 전개합니다',
      '왼쪽 레인에서 공격을 밀어붙입니다',
      '좌측을 열어젖히며 전진합니다',
    ],
    'right': [
      '오른쪽 측면으로 볼을 전개합니다',
      '오른쪽 레인에서 공격을 밀어붙입니다',
      '우측을 열어젖히며 전진합니다',
    ],
    'center': [
      '중원에서 패스로 전방을 엽니다',
      '중앙 통로를 파고들며 전진합니다',
      '센터에서 빌드업을 이어갑니다',
    ],
  };

  static const attackBuildDefault = [
    '패스로 전방을 열어젖힙니다',
    '동료와 연계하며 공격 위치를 잡습니다',
    '볼을 전진시키며 슈팅 각을 엿봅니다',
    '상대 진영으로 차근차근 올라갑니다',
  ];

  static const headerVerb = [
    '정확히 헤딩해',
    '강하게 헤딩해',
    '방향을 바꿔 헤딩해',
    '다이빙 헤딩으로',
    '일어서서 헤딩해',
  ];

  static const dribblePhrase = [
    '수비수를 제친 뒤',
    '돌파에 성공한 뒤',
    '개인기로 풀고',
    '상대를 따돌린 뒤',
    '드리블로 공간을 만든 뒤',
  ];

  static const oneOnOnePhrase = [
    '키퍼와 일대일에서',
    '원온원 상황에서',
    '골키퍼를 앞에 두고',
    '단독 찬스에서',
  ];

  static const counterPhrase = [
    '빠른 역습 끝에',
    '카운터어택으로',
    '역습 전개 후',
    '전환 공격에서',
  ];

  static const keeperTouchPhrase = [
    '키퍼 손끝을 스치며',
    '골키퍼가 손만 댔지만',
    '선방을 피해',
    '키퍼를 뚫고',
  ];

  static const foulTypeKo = {
    'hold': '홀딩',
    'push': '푸시',
    'late_tackle': '늦은 태클',
    'sliding': '슬라이딩',
    'trip': '트립',
    'handball': '핸드볼',
    'dangerous_play': '위험한 플레이',
  };

  static const cardNounYellow = ['옐로카드', '경고', '옐로'];
  static const cardNounRed = ['레드카드', '퇴장카드', '레드'];

  static const shotOutcome = {
    'offTarget': [
      '골문을 살짝 벗어납니다',
      '빗나갑니다',
      '옆으로 흐릅니다',
      '높이 뜨고 맙니다',
    ],
    'hitPost': [
      '골대를 강타합니다',
      '포스트를 맞춥니다',
      '크로스바를 때립니다',
      '골대가 울립니다',
    ],
    'saved': [
      '막아냅니다',
      '선방합니다',
      '잡아내습니다',
      '슈퍼세이브로 막아냅니다',
    ],
    'blocked': [
      '수비수에게 차단됩니다',
      '블로킹됩니다',
      '상대 수비에게 막힙니다',
    ],
  };

  static const cornerNear = [
    '니어 포스트로',
    '가까운 골대로',
    '니어 사이드로',
  ];
  static const cornerFar = [
    '파 포스트로',
    '먼 골대로',
    '파 사이드로',
  ];

  static String pick(
    SeededRandom rng,
    List<String> list, {
    String fallback = '',
  }) {
    if (list.isEmpty) return fallback;
    return rng.pick(list);
  }

  static String pickKeyed(
    SeededRandom rng,
    Map<String, List<String>> map,
    String? key, {
    String fallback = '',
  }) {
    if (key == null) return fallback;
    final list = map[key];
    if (list == null || list.isEmpty) return fallback;
    return rng.pick(list);
  }

  /// Count of discrete word entries used for Goal commentary (for tests).
  static int goalDictionaryEntryCount() {
    var n = 0;
    n += intensity.length;
    n += reaction.length;
    n += connector.length;
    for (final e in shotVerb.values) {
      n += e.length;
    }
    for (final e in footPhrase.values) {
      n += e.length;
    }
    for (final e in distancePhrase.values) {
      n += e.length;
    }
    for (final e in assistLead.values) {
      n += e.length;
    }
    n += headerVerb.length;
    n += dribblePhrase.length;
    n += oneOnOnePhrase.length;
    n += counterPhrase.length;
    n += keeperTouchPhrase.length;
    for (final e in styleTone.values) {
      n += e.length;
    }
    return n;
  }
}
