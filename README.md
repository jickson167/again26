# Again26 - 축구 매니저

Flutter Web + Supabase 기반 축구 매니저 웹게임.

## Windows에서 시작 (Cursor)

### 1. 필수 설치

| 도구 | 용도 |
|------|------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) | 앱 빌드·실행 |
| [Git](https://git-scm.com/download/win) | 저장소 클론 |
| [Chrome](https://www.google.com/chrome/) | Flutter Web 실행 |
| (선택) [GitHub CLI](https://cli.github.com/) | `deploy.ps1` 배포 |
| (선택) [Supabase CLI](https://supabase.com/docs/guides/cli) | Edge Function 배포 |

PowerShell에서 `flutter doctor` 로 Chrome·VS Code toolchain 확인.

### 2. 저장소 클론 후 설정

```powershell
git clone https://github.com/jickson167/again26.git
cd again26

# 최초 1회
.\setup.ps1
```

`env.json`이 없으면 `env.example.json`이 복사됩니다. 아래 값을 입력:

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_PUBLISHABLE_KEY"
}
```

Mac에서 쓰던 `generator_config.js`가 있으면 자동으로 `env.json`을 만듭니다.

### 3. 로컬 실행

```powershell
.\run_local.ps1
```

또는 더블클릭: `run_local.bat`

서버만 띄운 뒤 **평소 쓰는 Chrome**으로 매니저 페이지가 열립니다 (Google/네이버 자동로그인·지문 인식 유지).  
Flutter 디버그용 임시 Chrome 창은 더 이상 사용하지 않습니다.

| URL | 설명 |
|-----|------|
| http://localhost:8080/admin | 매니저(편집기) — **기본으로 열림** |
| http://localhost:8080/ | 게임 홈 |
| http://localhost:8080/home | 기존 메인 |

터미널: `r` hot reload · `R` hot restart · `q` 종료

### 4. Cursor / VS Code 디버그

1. `env.json` 설정
2. **Run and Debug (F5)** → **Again26 매니저 (Chrome)**

`prepare-local-run` 태스크가 `web/env.js`·`web/tools`를 자동 동기화합니다.

---

## macOS / Linux

```bash
./run_local.sh
```

매니저 페이지(`http://localhost:8080/admin`)가 **평소 쓰는 Chrome**에서 열립니다.

데스크탑 바로가기:

```bash
./scripts/mac/install_desktop_shortcuts.sh
```

---

## Supabase DB 마이그레이션

SQL Editor에서 순서대로 적용:

| 파일 | 내용 |
|------|------|
| `001` ~ `013` | 선수·감독·포메이션 등 |
| `014_game_clubs.sql` | 게임 구단 저장 |
| `012_coaches_rls.sql` | coaches RLS |

---

## 로그인

- **Google**: Supabase → Sign In / Providers → Google
- **네이버**: Custom Provider `custom:naver` + Edge Function `naver-userinfo`

네이버 Edge Function 배포 (Windows):

```powershell
supabase login
supabase link --project-ref ghjasnmmhwdxloscgcvc
.\scripts\deploy_naver_function.ps1
```

---

## 배포 (GitHub Pages)

```powershell
.\deploy.ps1
# 또는 메시지 지정
.\deploy.ps1 "게임 UI 업데이트"
```

- https://jickson167.github.io/again26/
- https://jickson167.github.io/again26/admin

GitHub Actions secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`

---

## 주요 라우트

| 경로 | 설명 |
|------|------|
| `/` | 게임 (Google/네이버 로그인) |
| `/game` | 게임 |
| `/home` | 기존 홈 |
| `/players` | 선수 목록 |
| `/admin` | 관리자 (선수·감독·생성기) |

---

## Windows 스크립트

| 파일 | 설명 |
|------|------|
| `setup.ps1` | 최초 `flutter pub get` + env 동기화 |
| `run_local.ps1` | Chrome 8080 로컬 실행 |
| `run_local.bat` | `run_local.ps1` 래퍼 |
| `deploy.ps1` | GitHub Pages 배포 |
| `scripts/write_web_env.ps1` | `env.json` → `web/env.js` |
| `scripts/sync_web_tools.ps1` | HTML 생성기 → `web/tools` |
| `scripts/deploy_naver_function.ps1` | 네이버 OAuth 프록시 배포 |

---

## 프로젝트 구조

```
lib/
  pages/game/     게임 UI·로그인
  pages/admin/    관리자
  services/       Supabase·Auth·GameClub
supabase/
  migrations/     DB 스키마
  functions/      Edge Functions (naver-userinfo 등)
web/
  env.js          로컬 Supabase 설정 (setup/run 시 생성)
  tools/          선수·감독 HTML 생성기
```

## 보안

MVP RLS는 anon CRUD 허용. 운영 전 `auth.uid()` 기반 정책으로 교체하세요.

`env.json`은 gitignore — **커밋하지 마세요.**
