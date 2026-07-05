import { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { CsvDropZone, Modal, SeedChips, Toolbar } from '../components/Common';
import { PlayerDetailPanel } from '../components/PlayerDetail';
import { downloadText } from '../lib/utils';
import { exportPlayersCsv, parsePlayersCsv } from '../services/csv';
import { deletePlayer, fetchPlayer, fetchPlayers, updatePlayer, upsertPlayers } from '../services/players';
import type { Player } from '../types';
import { POSITION_LABELS } from '../types';

export default function PlayersPage() {
  const nav = useNavigate();
  const [players, setPlayers] = useState<Player[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [importing, setImporting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [detail, setDetail] = useState<Player | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setPlayers(await fetchPlayers(search));
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => {
    void load();
  }, [load]);

  async function openDetail(p: Player) {
    try {
      setDetail((await fetchPlayer(p.id)) ?? p);
    } catch {
      setDetail(p);
    }
  }

  return (
    <div>
      <Toolbar
        onExport={() => downloadText(exportPlayersCsv(players), 'players.csv')}
        onAdd={() => nav('/admin/players/new')}
        addLabel="선수 추가"
        onGenerator={() => nav('/admin/player-generator')}
      />
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
      <CsvDropZone
        label="선수 CSV 업로드"
        busy={importing}
        onImport={async (text) => {
          setImporting(true);
          try {
            const parsed = parsePlayersCsv(text);
            if (!parsed.length) {
              alert('가져올 선수 데이터가 없습니다.');
              return;
            }
            await upsertPlayers(parsed);
            await load();
            alert(`${parsed.length}명 가져옴`);
          } catch (e) {
            alert(e instanceof Error ? e.message : String(e));
          } finally {
            setImporting(false);
          }
        }}
      />

      {loading && <p className="muted">불러오는 중…</p>}
      {error && <p className="error">{error}</p>}
      {!loading && !error && players.length === 0 && (
        <p className="muted center">등록된 선수가 없습니다.</p>
      )}

      <ul className="list">
        {players.map((p) => (
          <li key={p.id} className="list-item">
            <div className="list-main">
              <strong>{p.name}</strong>
              <div className="muted">
                {p.detail_position ?? POSITION_LABELS[p.position]} · 랭크 {p.rank ?? '-'}
              </div>
              <SeedChips seeds={p.seed_names} />
            </div>
            <div className="list-actions">
              <button type="button" className="icon-btn" title="상세" onClick={() => void openDetail(p)}>
                🔍
              </button>
              <Link to={`/admin/players/${p.id}/edit`} className="icon-btn" title="수정">
                ✏️
              </Link>
              <button
                type="button"
                className="icon-btn"
                title="삭제"
                onClick={async () => {
                  if (!confirm(`${p.name} 선수를 삭제하시겠습니까?`)) return;
                  await deletePlayer(p.id);
                  await load();
                }}
              >
                🗑
              </button>
            </div>
          </li>
        ))}
      </ul>

      <Modal open={!!detail} title={detail?.name ?? ''} onClose={() => setDetail(null)} wide>
        {detail && (
          <PlayerDetailPanel
            player={detail}
            onSaveComment={async (comment) => {
              await updatePlayer({ ...detail, comment });
              await load();
              setDetail({ ...detail, comment });
            }}
          />
        )}
      </Modal>
    </div>
  );
}
