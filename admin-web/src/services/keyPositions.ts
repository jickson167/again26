import { getSupabase } from '../lib/supabase';
import type { KeyPosition } from '../types';

const TABLE = 'key_positions';

export async function fetchKeyPositions(): Promise<KeyPosition[]> {
  const { data, error } = await getSupabase().from(TABLE).select('*').order('id', { ascending: true });
  if (error) throw error;
  return (data ?? []) as KeyPosition[];
}

export async function upsertKeyPositions(items: KeyPosition[]): Promise<void> {
  if (!items.length) return;
  const { error } = await getSupabase().from(TABLE).upsert(items);
  if (error) throw error;
}

export async function deleteKeyPosition(id: string): Promise<void> {
  const { error } = await getSupabase().from(TABLE).delete().eq('id', id);
  if (error) throw error;
}
