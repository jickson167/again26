import { useEffect, useState } from 'react';
import { downloadText } from '../lib/utils';
import { exportKeyPositionsCsv, parseKeyPositionsCsv } from '../services/csv';
import { deleteKeyPosition, fetchKeyPositions, upsertKeyPositions } from '../services/keyPositions';
import type { KeyPosition } from '../types';
import { POSITION_LABELS } from '../types';
import { CsvDropZone, Modal, Toolbar } from '../components/Common';

export default function KeyPositionsPage() {
  const [items, setItems] = useState<KeyPosition[]>([]);
  const [loading, setLoading] = useState(true);
  const [importing, setImporting] = useState(false);
  const [detail, setDetail] = useState<KeyPosition | null>(null);

  async function load() {
    setLoading(true);
    try {
      setItems(await fetchKeyPositions());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  return (
    <div>
      <Toolbar onExport={() => downloadText(exportKeyPositionsCsv(items), 'key_positions.csv')} />
      <CsvDropZone
        label="키포지션 CSV 업로드"
        busy={importing}
        onImport={async (text) => {
          setImporting(true);
          try {
            const parsed = parseKeyPositionsCsv(text);
            await upsertKeyPositions(parsed);
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
        <p className="muted center">등록된 키포지션이 없습니다.</p>
      ) : (
        <ul className="list">
          {items.map((k) => (
            <li key={k.id} className="list-item">
              <div className="list-main">
                <strong>{k.name}</strong>
                <div className="muted">
                  {POSITION_LABELS[k.simple_position]} · {k.main_stat}/{k.sub_stat} · {k.id}
                </div>
              </div>
              <div className="list-actions">
                <button type="button" className="icon-btn" onClick={() => setDetail(k)}>
                  🔍
                </button>
                <button
                  type="button"
                  className="icon-btn"
                  onClick={async () => {
                    if (!confirm(`${k.name} 삭제?`)) return;
                    await deleteKeyPosition(k.id);
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
            <dt>포지션</dt><dd>{POSITION_LABELS[detail.simple_position]}</dd>
            <dt>주/부 스탯</dt><dd>{detail.main_stat} / {detail.sub_stat}</dd>
            <dt>멘탈/팀</dt><dd>{detail.mental_pref} / {detail.team_pref}</dd>
            {detail.description && (
              <>
                <dt>설명</dt><dd>{detail.description}</dd>
              </>
            )}
          </dl>
        )}
      </Modal>
    </div>
  );
}
