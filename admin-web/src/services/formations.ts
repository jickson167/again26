import { getSupabase } from '../lib/supabase';
import type { Formation } from '../types';

const TABLE = 'formations';

export async function fetchFormations(): Promise<Formation[]> {
  const { data, error } = await getSupabase().from(TABLE).select('*').order('id', { ascending: true });
  if (error) throw error;
  return (data ?? []) as Formation[];
}

export async function upsertFormations(items: Formation[]): Promise<void> {
  if (!items.length) return;
  const { error } = await getSupabase().from(TABLE).upsert(items);
  if (error) throw error;
}

export async function deleteFormation(id: string): Promise<void> {
  const { error } = await getSupabase().from(TABLE).delete().eq('id', id);
  if (error) throw error;
}
