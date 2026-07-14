/**
 * simulate-match Edge Function — dry-run by default.
 * Official persist/accumulation is a later phase.
 */
import {
  mergeConfig,
  simulateMatch,
  type MatchSimulationInput,
} from "../_shared/match_engine/index.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    if (req.method !== "POST") {
      return json({ error: "POST required" }, 405);
    }

    const body = await req.json() as {
      input?: MatchSimulationInput;
      dryRun?: boolean;
    };

    if (!body.input) {
      return json({
        error: "input required",
        note:
          "Dry-run: pass MatchSimulationInput. Production will load snapshots from DB only.",
      }, 400);
    }

    const dryRun = body.dryRun !== false;
    const result = simulateMatch(body.input, mergeConfig());

    return json({
      ok: true,
      dryRun,
      persisted: false,
      dbAccumulation: false,
      warning:
        "테스트 경기 — DB 저장 안 됨 · 선수 통산 기록 반영 안 됨",
      result,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
