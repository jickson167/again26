# Match Engine (TypeScript / Deno)

Pure football match simulation for Again26. **Official results are computed on the server** (Supabase Edge Function), never by the Flutter client.

## Layout

- `_shared/match_engine/` — pure functions (no DB)
- `simulate-match/` — Edge Function skeleton (dry-run only in phase 1)

## Run tests

```bash
export PATH="$HOME/.deno/bin:$PATH"

# Unit tests
deno test --allow-net=deno.land \
  supabase/functions/_shared/match_engine/tests/match_engine_test.ts

# Monte Carlo (~10k matches × scenarios)
deno test --allow-net=deno.land \
  supabase/functions/_shared/match_engine/tests/monte_carlo_balance_test.ts
```

## API

```ts
import { simulateMatch } from "./index.ts";

const result = simulateMatch({
  matchId: "match_1",
  seed: 58301922,
  simulationVersion: "1.0.0",
  home: { /* TeamSimulationSnapshot */ },
  away: { /* TeamSimulationSnapshot */ },
});
```

Same `seed` + snapshots + `simulationVersion` → identical result.
