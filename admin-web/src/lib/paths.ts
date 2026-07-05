export function generatorPageUrl(): string {
  const base = import.meta.env.BASE_URL.replace(/\/?$/, '/');
  return `${window.location.origin}${base}tools/player_row_generator_v3.html`;
}
