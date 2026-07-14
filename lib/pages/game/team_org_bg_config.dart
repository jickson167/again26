import 'dart:ui' show Rect, Offset;

/// 팀 조직 배경 이미지 정렬 설정.
///
/// 이미지에 경기장 라인이 그려져 있고, 오른쪽·아래에 벤치/정보용 여백이 있을 때
/// **이미지 속 경기장 영역**을 **선발 패널**에 맞춰 붙입니다.
/// PC(후보 오른쪽) / 모바일(후보 아래) 모두 같은 방식으로, 선발 패널 위치만 따라갑니다.
///
/// ## 맞추는 방법
/// 1. `assets/images/team_organization_bg.png` 배치
/// 2. `debugShowPitchRegion = true` 로 켠 뒤 hot restart
/// 3. 빨간 박스(= 선발 패널)와 이미지 라인 박스가 겹치도록
///    [pitchRegionInImage] / [desktopNudge] / [compactNudge] / scale 조정
/// 4. 맞으면 debug 끄기
class TeamOrgBgConfig {
  TeamOrgBgConfig._();

  static const assetCandidates = [
    'assets/images/team_organization_bg.png',
    'assets/images/team_organization_bg.jpg',
    'assets/images/team_organization_bg.webp',
  ];

  /// 이미지 안에서 경기장(라인)이 차지하는 영역. 값 범위 0.0 ~ 1.0
  /// (left, top, right, bottom)
  ///
  /// 예: 왼쪽 절반·위쪽 85%가 경기장이면 `Rect.fromLTRB(0, 0, 0.50, 0.85)`
  static const Rect pitchRegionInImage = Rect.fromLTRB(0.0, 0.0, 0.50, 0.85);

  /// PC 레이아웃 미세 이동 (부모 크기 대비 비율). +x 오른쪽, +y 아래
  static const Offset desktopNudge = Offset.zero;

  /// 모바일(compact) 미세 이동
  static const Offset compactNudge = Offset.zero;

  /// 1.0 = 선발 패널에 경기장 영역을 딱 맞춤. 1.05 = 5% 확대
  static const double desktopScale = 1.0;
  static const double compactScale = 1.0;

  /// true면 선발 패널 위치에 빨간 테두리 표시 (정렬용)
  static const bool debugShowPitchRegion = true;

  /// 배경 이미지가 라인을 갖고 있으면 true — 코드로 그리는 피치 라인 숨김
  static const bool hideDrawnPitchLines = true;
}
