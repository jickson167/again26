import 'dart:math';

import 'package:again26/models/game_club.dart';
import 'package:again26/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

Player _p(
  String id, {
  int pk = 0,
  int fk = 0,
  int ck = 0,
  int leadership = 0,
}) {
  return Player.empty(id: id).copyWith(
    name: id,
    pkAbility: pk,
    fkAbility: fk,
    ckAbility: ck,
    leadership: leadership,
  );
}

void main() {
  test('능력치 최고자에게 각 역할 배정', () {
    final starters = [
      _p('a', pk: 8, fk: 3, ck: 2, leadership: 4),
      _p('b', pk: 5, fk: 9, ck: 1, leadership: 3),
      _p('c', pk: 4, fk: 2, ck: 10, leadership: 2),
      _p('d', pk: 1, fk: 1, ck: 1, leadership: 9),
    ];
    final roles = GameClub.assignDefaultRoles(
      starters,
      random: Random(1),
    )!;

    expect(roles.pkPlayerId, 'a');
    expect(roles.fkPlayerId, 'b');
    expect(roles.ckPlayerId, 'c');
    expect(roles.captainPlayerId, 'd');
  });

  test('한 선수가 네 역할 모두 가능', () {
    final starters = [
      _p('star', pk: 10, fk: 10, ck: 10, leadership: 10),
      _p('other', pk: 1, fk: 1, ck: 1, leadership: 1),
    ];
    final roles = GameClub.assignDefaultRoles(
      starters,
      random: Random(0),
    )!;

    expect(roles.pkPlayerId, 'star');
    expect(roles.fkPlayerId, 'star');
    expect(roles.ckPlayerId, 'star');
    expect(roles.captainPlayerId, 'star');
  });

  test('선발 1명이면 4역할 모두 그 선수', () {
    final starters = [_p('only', pk: 3, fk: 4, ck: 5, leadership: 6)];
    final roles = GameClub.assignDefaultRoles(
      starters,
      random: Random(0),
    )!;

    expect(roles.pkPlayerId, 'only');
    expect(roles.fkPlayerId, 'only');
    expect(roles.ckPlayerId, 'only');
    expect(roles.captainPlayerId, 'only');
  });

  test('동점이면 동점자 집합 안에서만 선택', () {
    final starters = [
      _p('a', pk: 7),
      _p('b', pk: 7),
      _p('c', pk: 5),
    ];
    final seen = <String>{};
    for (var seed = 0; seed < 40; seed++) {
      final id = GameClub.pickBestByAbility(
        starters,
        (p) => p.pkAbility,
        Random(seed),
      );
      seen.add(id);
      expect(['a', 'b'], contains(id));
    }
    expect(seen, containsAll(['a', 'b']));
  });

  test('ensureRolesOnStarters는 후보/null 역할만 능력치로 채움', () {
    final starters = [
      _p('a', pk: 10, fk: 1, ck: 1, leadership: 1),
      _p('b', pk: 1, fk: 10, ck: 1, leadership: 1),
      _p('c', pk: 1, fk: 1, ck: 10, leadership: 10),
    ];
    final filled = GameClub.ensureRolesOnStarters(
      starters: starters,
      pkPlayerId: 'bench-guy',
      fkPlayerId: 'b',
      ckPlayerId: null,
      captainPlayerId: 'c',
      random: Random(0),
    )!;

    expect(filled.pkPlayerId, 'a');
    expect(filled.fkPlayerId, 'b');
    expect(filled.ckPlayerId, 'c');
    expect(filled.captainPlayerId, 'c');
  });

  test('스왑 역할 이전: 내려간 선수 역할을 올라온 선수에게', () {
    final transferred = GameClub.transferRoles(
      fromPlayerId: 'starter',
      toPlayerId: 'bench',
      pkPlayerId: 'starter',
      fkPlayerId: 'starter',
      ckPlayerId: 'other',
      captainPlayerId: 'starter',
    );

    expect(transferred.pkPlayerId, 'bench');
    expect(transferred.fkPlayerId, 'bench');
    expect(transferred.ckPlayerId, 'other');
    expect(transferred.captainPlayerId, 'bench');
  });

  test('빈 선발이면 null', () {
    expect(GameClub.assignDefaultRoles(const []), isNull);
    expect(
      GameClub.ensureRolesOnStarters(starters: const []),
      isNull,
    );
  });
}
