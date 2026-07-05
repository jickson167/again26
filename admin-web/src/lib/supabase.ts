import { createClient, SupabaseClient } from '@supabase/supabase-js';

let client: SupabaseClient | null = null;

export function getSupabase(): SupabaseClient {
  if (client) return client;

  const cfg = window.AGAIN26_CONFIG ?? {};
  const url = cfg.SUPABASE_URL?.trim() ?? '';
  const key = cfg.SUPABASE_ANON_KEY?.trim() ?? '';

  if (!url || !key) {
    throw new Error('Supabase 설정이 없습니다. env.js를 확인하세요.');
  }

  client = createClient(url, key);
  return client;
}

export function isSupabaseConfigured(): boolean {
  const cfg = window.AGAIN26_CONFIG ?? {};
  return Boolean(cfg.SUPABASE_URL?.trim() && cfg.SUPABASE_ANON_KEY?.trim());
}
