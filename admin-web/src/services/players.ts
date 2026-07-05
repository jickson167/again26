import { getSupabase } from '../lib/supabase';
import type { Player } from '../types';

const TABLE = 'players';

export async function fetchPlayers(search?: string): Promise<Player[]> {
  let q = getSupabase().from(TABLE).select('*').order('id', { ascending: true });
  if (search?.trim()) {
    q = q.or(`name.ilike.%${search.trim()}%,fake_name.ilike.%${search.trim()}%`);
  }
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as Player[];
}

export async function fetchPlayer(id: string): Promise<Player | null> {
  const { data, error } = await getSupabase().from(TABLE).select('*').eq('id', id).maybeSingle();
  if (error) throw error;
  return (data as Player | null) ?? null;
}

export async function upsertPlayers(players: Player[]): Promise<void> {
  if (!players.length) return;
  const { error } = await getSupabase().from(TABLE).upsert(players);
  if (error) throw error;
}

export async function updatePlayer(player: Player): Promise<void> {
  const { id, ...rest } = player;
  const { error } = await getSupabase().from(TABLE).update(rest).eq('id', id);
  if (error) throw error;
}

export async function deletePlayer(id: string): Promise<void> {
  const { error } = await getSupabase().from(TABLE).delete().eq('id', id);
  if (error) throw error;
}
