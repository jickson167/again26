# Again26 - 축구 매니저 MVP

Flutter Web + Supabase 기반 축구 매니저 웹게임 1단계 MVP입니다.

## 1단계 기능

- Supabase 연결
- 선수 마스터 데이터 구조 (`players` 테이블)
- 관리자 페이지: 선수 추가/수정/삭제
- 선수 목록 페이지
- 선수 상세 페이지
- CSV import/export

## Supabase 설정

1. [Supabase](https://supabase.com)에서 프로젝트 생성
2. SQL Editor에서 `supabase/migrations/001_players.sql` 실행
3. Project Settings → API에서 URL과 `anon` key 확인

## 실행

```bash
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Windows PowerShell:

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 라우트

| 경로 | 설명 |
|------|------|
| `/` | 홈 |
| `/players` | 선수 목록 |
| `/players/:id` | 선수 상세 |
| `/admin` | 관리자 선수 목록 (CSV, CRUD) |
| `/admin/new` | 선수 추가 |
| `/admin/:id/edit` | 선수 수정 |

## 선수 데이터 필드

| 필드 | 설명 |
|------|------|
| `id` | UUID |
| `name` | 이름 |
| `fake_name` | 가명 |
| `position` | fw, mf, df, gk |
| `position_fit` | 적정포지션 1~13 (각 0~10, JSONB) |
| `rank` | 랭크 |
| `age_stage` | 연령 단계 |
| `height` / `weight` | 키(cm), 몸무게(kg) |
| `nationality` | 국적 |
| `growth_type` | 1기~10기 성장 [{speed, power, technique}] |
| `speed`, `power`, `technique` | 0~10 |
| `pk_ability`, `fk_ability`, `ck_ability` | 0~10 |
| `leadership` | 0~10 |
| `intelligence_sense` | 0=지력10, 10=감각10 |
| `individual_organization` | 0=개인10, 10=조직10 |
| `portrait_url` | 초상 URL |
| `created_at`, `updated_at` | 타임스탬프 |

## CSV

- 샘플: `supabase/templates/players_sample.csv`
- 관리자 페이지 상단 버튼으로 가져오기/내보내기
- `id`가 있으면 upsert, 없으면 신규 생성

## 프로젝트 구조

```
lib/
  config/          Supabase 설정
  models/          Player, Growth, Position
  services/        PlayerService, CsvService
  pages/           홈, 목록, 상세, 관리자
  router/          go_router
  widgets/         공통 UI
supabase/
  migrations/      DB 스키마
  templates/       CSV 샘플
```

## 보안 참고

MVP에서는 anon 키로 CRUD가 가능하도록 RLS 정책을 열어두었습니다. 운영 환경에서는 Supabase Auth와 관리자 전용 정책으로 교체하세요.
