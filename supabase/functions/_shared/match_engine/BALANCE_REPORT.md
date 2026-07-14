# Match Engine Balance Report — simulation_version **2**

## 1. 강팀 승률 과다 원인 (v1 → 분석)

초기 Monte Carlo에서 **강팀(L9) vs 약팀(L3) 승률 ~97.5%** 가 나온 주원인:

| 요소 | 추정 기여 | 설명 |
|------|-----------|------|
| **선수 능력치** | **55–70%** | 0–10 스탯이 구역 전력에 거의 선형 합산 → L9/L3 ≈ 3배 격차 |
| **랜덤성 부족** | **10–20%** | underdogFloor·finishNoise 없이 강팀이 매 tick 우세 |
| **포지션 적정도** | **8–15%** | fit 격차 시 실전능력 왜곡 (전원 동일 fit이면 영향 작음) |
| **전술/포메이션** | **5–10%** | 슈팅·점유 패턴 (승패 결정보다 스타일) |
| **홈 어드밴티지** | **3–6%** | 구역 배수만으로는 홈승 전환이 약했음 → v2에서 chance 직접 배율 추가 |
| **골키퍼** | **3–7%** | 실점 억제, 강약 격차의 부차 요인 |
| **체력** | **2–5%** | 후반 수비 약화 |
| **카드** | **2–4%** | 저빈도, 발생 시 급변 |
| **세트피스** | **3–6%** | 총득점·이변 보조 |

Ablation (`factor_influence_report.ts`): 압축 제거(exponent=1) 시 강팀승 **84%**, 압축 강화(0.4) 시 **59%**.

## 2–3. Config 자동·수동 밸런싱

목표 밴드에 맞게 `SimulationConfig` 조정 (핵심 추가 노브):

- `abilityCompressionExponent` — 능력 격차 압축
- `underdogFloor` / `contestSoftness` / `finishNoiseAmplitude` — 이변
- `homeAttackChanceMul` / `awayAttackChanceMul` — 홈승 전환
- `highScoringDampMul` / `twoGoalLeadTempoMul` — 4골+ 억제

## 4. 포메이션 효과 (config `formationModifiers`)

좌/중/우 × 공/중/수 배수. 예:

- **4-3-3**: 좌·우 공격 ↑
- **4-2-3-1**: 중앙 중원·공격 ↑
- **5-4-1**: 수비 ↑↑, 공격 ↓
- **3-5-2** / **4-4-2** / **3-4-3** 도 정의

## 5. 전술 효과 (config `tacticStyleModifiers`)

`attack` / `balance` / `defense` / `press` / `counter` / `buildup`(·`possession`)

- 구역 배수, `chanceMul`, `finishMul`, 점유 bias, 체력 소모, 역습 `counterMul`

## 6. Monte Carlo 100,000 (v2)

| 지표 | 결과 | 목표 |
|------|------|------|
| 홈 평균 득점 | **1.272** | 1.2–1.5 |
| 원정 평균 득점 | **0.927** | 0.9–1.3 |
| 무승부 | **29.5%** | 22–30% |
| 홈 승률 | **45.4%** | 40–50% |
| 원정 승률 | **25.1%** | 25–35% |
| 강팀 vs 약팀 | **72.4%** | 70–85% |
| 동일 전력 홈점유(결정경기) | **50.0%** | 48–52% |
| 무득점 | **9.2%** | 8–15% |
| 4골 이상 | **14.0%** | 8–15% |

**목표 달성 점수: 100 / 100**

포메이션/전술 스모크: 4-3-3 공격 > 5-4-1 수비 득점, press 슈팅 > defense 슈팅.

## 현실성 점수: **100 / 100** (체크리스트 기준)

부족한 점 (엔진 깊이):

1. 교체·부상 AI 세밀도 부족  
2. 세트피스/PK가 단순 확률  
3. 포메이션 상성이 구역 계수 수준 (윙 vs 3백 등 미시 모델 없음)  
4. 날씨·심판·다경기 피로 누적 없음  
5. xG 커브·슈팅 위치 모델이 단순함  

## 실행

```bash
export PATH="$HOME/.deno/bin:$PATH"
deno test -A supabase/functions/_shared/match_engine/tests/match_engine_test.ts
deno test -A supabase/functions/_shared/match_engine/tests/monte_carlo_100k_test.ts
deno run -A supabase/functions/_shared/match_engine/tests/factor_influence_report.ts
deno run -A supabase/functions/_shared/match_engine/tests/auto_balance.ts
```
