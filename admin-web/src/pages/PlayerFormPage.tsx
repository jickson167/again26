import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { fetchPlayer, updatePlayer, upsertPlayers } from '../services/players';
import type { Player, PlayerPosition } from '../types';

const emptyPlayer = (): Player => ({
  id: '',
  name: '',
  position: 'mf',
  position_fit: Object.fromEntries(Array.from({ length: 13 }, (_, i) => [String(i + 1), 0])),
  growth_type: Array.from({ length: 10 }, () => ({ speed: 0, power: 0, technique: 0 })),
  speed: 0,
  power: 0,
  technique: 0,
  shooting: 0,
  passing: 0,
  defense: 0,
  stamina: 0,
  goalkeeper: 0,
  pk_ability: 0,
  fk_ability: 0,
  ck_ability: 0,
  leadership: 0,
  intelligence_sense: 5,
  individual_organization: 5,
  seed_names: [],
});

export default function PlayerFormPage() {
  const { id } = useParams();
  const isNew = !id || id === 'new';
  const nav = useNavigate();
  const [player, setPlayer] = useState<Player>(emptyPlayer());
  const [loading, setLoading] = useState(!isNew);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (isNew || !id) return;
    void (async () => {
      setLoading(true);
      const p = await fetchPlayer(id);
      if (p) setPlayer(p);
      setLoading(false);
    })();
  }, [id, isNew]);

  if (loading) return <p className="muted">불러오는 중…</p>;

  return (
    <div className="form-page">
      <Link to="/" className="back-link">
        ← 선수 목록
      </Link>
      <h2>{isNew ? '선수 추가' : '선수 수정'}</h2>
      <p className="muted">
        상세 능력치·성장곡선은 <Link to="/player-generator">선수 생성기</Link> 사용을 권장합니다.
      </p>
      <form
        className="form-grid"
        onSubmit={async (e) => {
          e.preventDefault();
          setSaving(true);
          try {
            if (isNew) {
              await upsertPlayers([player]);
            } else {
              await updatePlayer(player);
            }
            nav('/');
          } catch (err) {
            alert(err instanceof Error ? err.message : String(err));
          } finally {
            setSaving(false);
          }
        }}
      >
        <label>
          ID
          <input
            className="input"
            value={player.id}
            disabled={!isNew}
            onChange={(e) => setPlayer({ ...player, id: e.target.value })}
            required
          />
        </label>
        <label>
          이름
          <input
            className="input"
            value={player.name}
            onChange={(e) => setPlayer({ ...player, name: e.target.value })}
            required
          />
        </label>
        <label>
          가명
          <input
            className="input"
            value={player.fake_name ?? ''}
            onChange={(e) => setPlayer({ ...player, fake_name: e.target.value || null })}
          />
        </label>
        <label>
          포지션
          <select
            className="input"
            value={player.position}
            onChange={(e) => setPlayer({ ...player, position: e.target.value as PlayerPosition })}
          >
            <option value="fw">FW</option>
            <option value="mf">MF</option>
            <option value="df">DF</option>
            <option value="gk">GK</option>
          </select>
        </label>
        <label>
          상세 포지션
          <input
            className="input"
            value={player.detail_position ?? ''}
            onChange={(e) => setPlayer({ ...player, detail_position: e.target.value || null })}
          />
        </label>
        <label>
          랭크 (1~5)
          <input
            className="input"
            type="number"
            min={1}
            max={5}
            value={player.rank ?? ''}
            onChange={(e) =>
              setPlayer({ ...player, rank: e.target.value ? parseInt(e.target.value, 10) : null })
            }
          />
        </label>
        <label>
          국적
          <input
            className="input"
            value={player.nationality ?? ''}
            onChange={(e) => setPlayer({ ...player, nationality: e.target.value || null })}
          />
        </label>
        <label className="full">
          시드 카테고리 (; 구분)
          <input
            className="input"
            value={(player.seed_names ?? []).join('; ')}
            onChange={(e) =>
              setPlayer({
                ...player,
                seed_names: e.target.value
                  .split(/[;；|]/)
                  .map((s) => s.trim())
                  .filter(Boolean),
              })
            }
            placeholder="일반시드; 2026 월드컵 대한민국 선발"
          />
        </label>
        <label className="full">
          코멘트
          <textarea
            className="input"
            rows={4}
            value={player.comment ?? ''}
            onChange={(e) => setPlayer({ ...player, comment: e.target.value || null })}
          />
        </label>
        <div className="form-actions full">
          <button type="submit" className="btn btn-primary" disabled={saving}>
            {saving ? '저장 중…' : '저장'}
          </button>
        </div>
      </form>
    </div>
  );
}
