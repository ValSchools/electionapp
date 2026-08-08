import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
const cors = {"Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"};
serve(async req => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const sheetUrl = Deno.env.get("GOOGLE_SHEET_WEBAPP_URL");
    if (!sheetUrl) throw new Error("GOOGLE_SHEET_WEBAPP_URL not configured");
    const body = await req.json();
    const { voterId, voterName, position, candidate, isAbstain, ballotId, castAt } = body;
    const res = await fetch(sheetUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ voterId, voterName, position, candidate, isAbstain, ballotId, castAt })
    });
    if (!res.ok) throw new Error("Google Sheets webapp returned " + res.status);
    return new Response(JSON.stringify({ ok: true }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message || String(e) }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
});