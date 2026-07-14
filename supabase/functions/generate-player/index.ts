import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const KEY_POSITION_IDS = [
  "kp_poacher", "kp_target_forward", "kp_false_nine", "kp_wing_forward_l",
  "kp_wing_forward_r", "kp_playmaker", "kp_trequartista", "kp_box_to_box",
  "kp_anchor", "kp_wingback_l", "kp_wingback_r", "kp_center_back", "kp_sweeper",
  "kp_ball_playing_cb", "kp_sweeper_keeper", "kp_shot_stopper", "kp_second_striker",
  "kp_pressing_forward", "kp_inside_forward_l", "kp_inside_forward_r",
  "kp_classic_striker", "kp_regista", "kp_mezzala_l", "kp_mezzala_r",
  "kp_ball_winning_midfielder", "kp_carrier", "kp_shadow_striker",
  "kp_wide_playmaker_l", "kp_wide_playmaker_r", "kp_overlapping_fullback_l",
  "kp_overlapping_fullback_r", "kp_defensive_fullback_l", "kp_defensive_fullback_r",
  "kp_stopper_cb", "kp_libero", "kp_build_up_keeper", "kp_line_keeper",
];

const SYSTEM_PROMPT = `You generate fictional football manager player data for the game Again26.
Return ONLY valid JSON matching the schema. No markdown.

Rules:
- Stats are integers 0-10.
- rank: 1-5 (5 = world class).
- simple_position: one of fw, mf, df, gk.
- detail_position: e.g. LW/ST, CB, GK (Korean game uses slash combos).
- fake_name: parody name (change last syllable), never identical to real name.
- current_age: 16-40 game display age.
- peak_pattern: early (peak stage 1-2), mid (3-5), or late (6-7).
- peak_stage: integer 1-7 matching peak_pattern.
- nationality: country name in Korean when possible.
- recommend_key_positions: exactly 5 distinct ids from the allowed list, best fit first.
- pos_1 through pos_13: slot fit 1-10 (13 = GK slot).

Allowed key position ids:
${KEY_POSITION_IDS.join(", ")}`;

const JSON_SCHEMA = `{
  "fake_name": "string",
  "detail_position": "string",
  "simple_position": "fw|mf|df|gk",
  "rank": 1,
  "current_age": 25,
  "peak_pattern": "mid",
  "peak_stage": 4,
  "height": 180,
  "weight": 75,
  "nationality": "대한민국",
  "speed": 7, "power": 7, "technique": 7,
  "shooting": 6, "passing": 6, "stamina": 6,
  "pk_ability": 5, "fk_ability": 5, "ck_ability": 5,
  "leadership": 5,
  "recommend_key_positions": ["kp_poacher", "kp_classic_striker", "kp_second_striker", "kp_pressing_forward", "kp_wing_forward_l"],
  "pos_1": 1, "pos_2": 1, "pos_3": 1, "pos_4": 1, "pos_5": 1, "pos_6": 1,
  "pos_7": 1, "pos_8": 1, "pos_9": 1, "pos_10": 1, "pos_11": 1, "pos_12": 1, "pos_13": 1
}`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) {
      return json({ error: "OPENAI_API_KEY not configured on Supabase" }, 503);
    }

    const { name, hint } = await req.json();
    if (!name || typeof name !== "string") {
      return json({ error: "name required" }, 400);
    }

    const model = Deno.env.get("OPENAI_MODEL") || "gpt-4o-mini";
    const userText = hint
      ? `Create player data for: ${name}\nExtra hints: ${hint}`
      : `Create player data inspired by or themed around: ${name}`;

    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          {
            role: "user",
            content: `${userText}\n\nSchema example:\n${JSON_SCHEMA}`,
          },
        ],
        temperature: 0.85,
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      return json({ error: err || `OpenAI HTTP ${res.status}` }, 502);
    }

    const body = await res.json();
    const content = body.choices?.[0]?.message?.content;
    if (!content) {
      return json({ error: "Empty OpenAI response" }, 502);
    }

    const player = JSON.parse(content);
    normalizePlayer(player);
    return json(player);
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function clamp(n: number, min: number, max: number) {
  return Math.max(min, Math.min(max, Math.round(n)));
}

function normalizePlayer(p: Record<string, unknown>) {
  const stat = (k: string, d = 0) => {
    p[k] = clamp(Number(p[k] ?? d), 0, 10);
  };
  ["speed", "power", "technique", "shooting", "passing", "stamina",
    "pk_ability", "fk_ability", "ck_ability", "leadership"].forEach((k) => stat(k));
  delete p.defense;
  delete p.goalkeeper;
  delete p.intelligence_sense;
  delete p.individual_organization;
  p.rank = clamp(Number(p.rank ?? 3), 1, 5);
  p.current_age = clamp(Number(p.current_age ?? 25), 16, 40);
  p.height = clamp(Number(p.height ?? 180), 150, 220);
  p.weight = clamp(Number(p.weight ?? 75), 45, 120);
  const pattern = String(p.peak_pattern ?? "mid");
  p.peak_pattern = ["early", "mid", "late"].includes(pattern) ? pattern : "mid";
  p.peak_stage = clamp(Number(p.peak_stage ?? 4), 1, 7);
  p.simple_position = ["fw", "mf", "df", "gk"].includes(String(p.simple_position))
    ? p.simple_position
    : "mf";
  for (let i = 1; i <= 13; i++) {
    p[`pos_${i}`] = clamp(Number(p[`pos_${i}`] ?? 1), 1, 10);
  }
  let recs = p.recommend_key_positions;
  if (!Array.isArray(recs)) recs = [];
  p.recommend_key_positions = recs
    .map(String)
    .filter((id) => KEY_POSITION_IDS.includes(id))
    .slice(0, 5);
  while (p.recommend_key_positions.length < 5) {
    const fallback = KEY_POSITION_IDS[p.recommend_key_positions.length];
    if (!p.recommend_key_positions.includes(fallback)) {
      p.recommend_key_positions.push(fallback);
    }
  }
}
