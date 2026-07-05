export function generatorPageUrl(): string {
  const base = import.meta.env.BASE_URL.replace(/\/?$/, '/');
  const root = base.replace(/admin\/$/, '');
  return `${window.location.origin}${root}tools/player_row_generator_v3.html`;
}
