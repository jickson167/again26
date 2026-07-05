import { useEffect, useState } from 'react';
import { downloadText } from '../lib/utils';
import { exportFormationsCsv, parseFormationsCsv } from '../services/csv';
import { deleteFormation, fetchFormations, upsertFormations } from '../services/formations';
import type { Formation } from '../types';
import { CsvDropZone, Modal, Toolbar } from '../components/Common';

export default function FormationsPage() {
  const [items, setItems] = useState<Formation[]>([]);
  const [loading, setLoading] = useState(true);
  const [importing, setImporting] = useState(false);
  const [detail, setDetail] = useState<Formation | null>(null);

  async function load() {
    setLoading(true);
    try {
      setItems(await fetchFormations());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  return (
    <div>
      <Toolbar onExport={() => downloadText(exportFormationsCsv(items), 'formations.csv')} />
      <CsvDropZone
        label="포메이션 CSV 업로드"
        busy={importing}
        onImport={async (text) => {
          setImporting(true);
          try {
            const parsed = parseFormationsCsv(text);
            await upsertFormations(parsed);
            await load();
            alert(`${parsed.length}개 가져옴`);
          } catch (e) {
            alert(e instanceof Error ? e.message : String(e));
          } finally {
            setImporting(false);
          }
        }}
      />
      {loading ? (
        <p className="muted">불러오는 중…</p>
      ) : items.length === 0 ? (
        <p className="muted center">등록된 포메이션이 없습니다.</p>
      ) : (
        <ul className="list">
          {items.map((f) => (
            <li key={f.id} className="list-item">
              <div className="list-main">
                <strong>{f.name}</strong>
                <div className="muted">
                  {f.formation_type ?? '-'} · 점유 {f.possession} / 공격 {f.attack} / 안정 {f.stability}
                </div>
              </div>
              <div className="list-actions">
                <button type="button" className="icon-btn" onClick={() => setDetail(f)}>
                  🔍
                </button>
                <button
                  type="button"
                  className="icon-btn"
                  onClick={async () => {
                    if (!confirm(`${f.name} 삭제?`)) return;
                    await deleteFormation(f.id);
                    await load();
                  }}
                >
                  🗑
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
      <Modal open={!!detail} title={detail?.name ?? ''} onClose={() => setDetail(null)}>
        {detail && (
          <dl className="info-grid">
            <dt>ID</dt><dd>{detail.id}</dd>
            <dt>타입</dt><dd>{detail.formation_type ?? '-'}</dd>
            <dt>점유/공격/안정</dt>
            <dd>{detail.possession} / {detail.attack} / {detail.stability}</dd>
            <dt>키포지션</dt>
            <dd>
              {[1, 2, 3].map((n) => {
                const id = detail[`key_pos_${n}` as keyof Formation];
                const slot = detail[`key_pos_${n}_slot` as keyof Formation];
                return id ? `${n}. ${String(id)} (슬롯 ${String(slot)})` : null;
              }).filter(Boolean).join(' · ') || '-'}
            </dd>
            {detail.comment && (
              <>
                <dt>코멘트</dt><dd>{detail.comment}</dd>
              </>
            )}
          </dl>
        )}
      </Modal>
    </div>
  );
}
