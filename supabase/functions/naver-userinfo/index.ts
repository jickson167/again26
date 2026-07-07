const NAVER_USERINFO_URL = "https://openapi.naver.com/v1/nid/me";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return Response.json(
      { error: "Missing Authorization header" },
      { status: 401, headers: corsHeaders },
    );
  }

  const naverResponse = await fetch(NAVER_USERINFO_URL, {
    headers: { Authorization: authorization },
  });

  if (!naverResponse.ok) {
    return Response.json(
      { error: "Failed to fetch user info from Naver" },
      { status: naverResponse.status, headers: corsHeaders },
    );
  }

  const data = await naverResponse.json();

  if (data.resultcode !== "00" || !data.response) {
    return Response.json(
      { error: data.message || "Naver API error" },
      { status: 502, headers: corsHeaders },
    );
  }

  const profile = data.response;
  const oidcUserinfo: Record<string, unknown> = {
    sub: profile.id,
  };

  if (profile.email) {
    oidcUserinfo.email = profile.email;
    oidcUserinfo.email_verified = true;
  }
  if (profile.name) {
    oidcUserinfo.name = profile.name;
  }
  if (profile.nickname) {
    oidcUserinfo.nickname = profile.nickname;
  }
  if (profile.profile_image) {
    oidcUserinfo.picture = profile.profile_image;
  }

  return Response.json(oidcUserinfo, {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
