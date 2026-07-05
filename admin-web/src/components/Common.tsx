import { displaySeeds } from '../lib/utils';

export function SeedChips({ seeds, dark = false }: { seeds: string[]; dark?: boolean }) {
  const labels = displaySeeds(seeds);
  return (
    <div className="seed-row">
      {dark && <span className="seed-label">시드 :</span>}
      <div className="seed-wrap">
        {labels.map((s) => (
          <span key={s} className={dark ? 'seed-pill seed-pill-dark' : 'seed-pill'}>
            {s}
          </span>
        ))}
      </div>
    </div>
  );
}

export function Stars({ rank }: { rank?: number | null }) {
  if (!rank) return null;
  return (
    <span className="stars" aria-label={`랭크 ${rank}`}>
      {'★'.repeat(Math.min(5, Math.max(0, rank)))}
    </span>
  );
}

export function Toolbar({
  onExport,
  onAdd,
  addLabel = '추가',
  onGenerator,
}: {
  onExport: () => void;
  onAdd?: () => void;
  addLabel?: string;
  onGenerator?: () => void;
}) {
  return (
    <div className="toolbar">
      <button type="button" className="btn btn-outline" onClick={onExport}>
        CSV 내보내기
      </button>
      {onGenerator && (
        <button type="button" className="btn btn-outline" onClick={onGenerator}>
          선수 생성기
        </button>
      )}
      {onAdd && (
        <button type="button" className="btn btn-primary" onClick={onAdd}>
          {addLabel}
        </button>
      )}
    </div>
  );
}

export function CsvDropZone({
  label,
  busy,
  onImport,
}: {
  label: string;
  busy?: boolean;
  onImport: (text: string) => void;
}) {
  return (
    <label className={`csv-drop ${busy ? 'busy' : ''}`}>
      <input
        type="file"
        accept=".csv,text/csv"
        disabled={busy}
        onChange={async (e) => {
          const file = e.target.files?.[0];
          if (!file) return;
          onImport(await file.text());
          e.target.value = '';
        }}
      />
      {busy ? '가져오는 중…' : label}
    </label>
  );
}

export function Modal({
  open,
  title,
  onClose,
  children,
  wide,
}: {
  open: boolean;
  title: string;
  onClose: () => void;
  children: React.ReactNode;
  wide?: boolean;
}) {
  if (!open) return null;
  return (
    <div className="modal-backdrop" onClick={onClose} role="presentation">
      <div
        className={`modal ${wide ? 'modal-wide' : ''}`}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <header className="modal-header">
          <h2>{title}</h2>
          <button type="button" className="icon-btn" onClick={onClose} aria-label="닫기">
            ✕
          </button>
        </header>
        <div className="modal-body">{children}</div>
      </div>
    </div>
  );
}
