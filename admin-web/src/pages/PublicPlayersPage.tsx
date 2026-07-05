import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { SeedChips, Stars } from '../components/Common';
import { fetchPlayers } from '../services/players';
import type { Player } from '../types';
import { POSITION_LABELS } from '../types';

export default function PublicPlayersPage() {
  const [players, setPlayers] = useState<Player[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setPlayers(await fetchPlayers(search));
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <div className="public-page">
      <header className="public-header">
        <Link to="/" className="back-link">
          ← 홈
        </Link>
        <h1>선수 목록</h1>
      </header>
      <div className="search-row">
        <input
          className="input"
          placeholder="이름 검색"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && void load()}
        />
        <button type="button" className="btn btn-outline" onClick={() => void load()}>
          검색
        </button>
      </div>
      {loading ? (
        <p className="muted">불러오는 중…</p>
      ) : (
        <ul className="list">
          {players.map((p) => (
            <li key={p.id} className="list-item">
              <Link to={`/players/${p.id}`} className="list-main list-link">
                <strong>{p.name}</strong>
                <div className="muted">
                  {POSITION_LABELS[p.position]}
                  {p.fake_name ? ` · 가명 ${p.fake_name}` : ''}
                  {p.rank != null ? ` · 랭크 ${p.rank}` : ''}
                  <Stars rank={p.rank} />
                </div>
                <SeedChips seeds={p.seed_names} />
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
