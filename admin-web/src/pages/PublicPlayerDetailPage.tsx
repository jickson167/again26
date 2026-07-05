import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { PlayerDetailPanel } from '../components/PlayerDetail';
import { fetchPlayer } from '../services/players';
import type { Player } from '../types';

export default function PublicPlayerDetailPage() {
  const { id } = useParams();
  const [player, setPlayer] = useState<Player | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    void (async () => {
      setLoading(true);
      setPlayer(await fetchPlayer(id));
      setLoading(false);
    })();
  }, [id]);

  if (loading) return <p className="muted public-page">불러오는 중…</p>;
  if (!player) return <p className="error public-page">선수를 찾을 수 없습니다.</p>;

  return (
    <div className="public-page">
      <Link to="/players" className="back-link">
        ← 선수 목록
      </Link>
      <PlayerDetailPanel player={player} />
    </div>
  );
}
