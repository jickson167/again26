# 팀 조직 배경 이미지

파일을 이 이름으로 넣으세요:

- `team_organization_bg.png` (또는 `.jpg` / `.webp`)

## 레이아웃 의도

이미지에 **경기장 라인**이 있고, **오른쪽·아래 여백**에 후보/선수정보가 올라가는 전제입니다.

- PC: 후보가 오른쪽 → 이미지 오른쪽 여백 사용
- 모바일: 후보가 아래 → 이미지 아래 여백 사용

코드는 `BoxFit.cover`로 대충 자르지 않고,
**이미지 속 경기장 영역**을 **선발 선수 패널**에 맞춰 붙입니다.

## 위치 맞추기 (수동 조정)

편집 파일: `lib/pages/game/team_org_bg_config.dart`

1. `debugShowPitchRegion = true` 로 변경 후 hot restart  
   → 선발 패널에 빨간 박스가 보입니다.
2. `pitchRegionInImage` 조정  
   - 이미지에서 라인이 그려진 사각형 (0~1 비율)  
   - 예: 왼쪽 50%·위 85%가 경기장 → `Rect.fromLTRB(0, 0, 0.50, 0.85)`
3. 살짝 어긋나면  
   - PC: `desktopNudge` / `desktopScale`  
   - 모바일: `compactNudge` / `compactScale`  
   - nudge: `Offset(0.01, -0.02)` = 오른쪽 1%, 위 2%
4. 맞으면 `debugShowPitchRegion = false`

픽셀 좌표를 패널마다 따로 찍을 필요는 없습니다.
선발 패널 크기·위치가 바뀌면 배경도 같이 따라갑니다.
