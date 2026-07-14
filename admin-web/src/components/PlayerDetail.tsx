import type { Player } from '../types';
import { FIELD_SLOTS, POSITION_LABELS } from '../types';
import { SeedChips, Stars } from './Common';

function normalizeFit(v: number): number {
  if (v <= 0) return 1;
  if (v > 7) return 7;
  return v;
}

function fitColor(v: number): string {
  const n = normalizeFit(v);
  if (n <= 1) return 'fit-1';
  if (n === 2) return 'fit-2';
  if (n === 3) return 'fit-3';
  if (n === 4) return 'fit-4';
  if (n === 5) return 'fit-5';
  return 'fit-67';
}

export function PositionFitGrid({ fit }: { fit: Record<string, number> }) {
  const rows = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
    [10, 11, 12],
    [null, 13, null],
  ];
  return (
    <div className="pitch">
      {rows.map((row, ri) => (
        <div key={ri} className="pitch-row">
          {row.map((slot, ci) =>
            slot == null ? (
              <div key={ci} className="pitch-cell empty" />
            ) : (
              <div
                key={slot}
                className={`pitch-cell ${fitColor(fit[String(slot)] ?? 0)}`}
              >
                <small>{FIELD_SLOTS[slot]}</small>
                <strong>{normalizeFit(fit[String(slot)] ?? 0)}</strong>
              </div>
            ),
          )}
        </div>
      ))}
    </div>
  );
}

export function PlayerDetailPanel({
  player,
  onSaveComment,
}: {
  player: Player;
  onSaveComment?: (comment: string) => Promise<void>;
}) {
  const displayPos = player.detail_position ?? POSITION_LABELS[player.position];

  return (
    <div className="player-detail">
      <div className="player-hero">
        <div className="player-hero-text">
          <div className="badges">
            <span className="badge">{POSITION_LABELS[player.position]}</span>
            <Stars rank={player.rank} />
          </div>
          <div className="sub">{displayPos}</div>
          <h3>{player.name}</h3>
          {player.fake_name && <div className="fake">{player.fake_name}</div>}
          <SeedChips seeds={player.seed_names} dark />
        </div>
      </div>

      <section>
        <h4>기본 정보</h4>
        <dl className="info-grid">
          {player.nationality && (
            <>
              <dt>국적</dt>
              <dd>{player.nationality}</dd>
            </>
          )}
          {player.height != null && (
            <>
              <dt>키</dt>
              <dd>{player.height} cm</dd>
            </>
          )}
          {player.weight != null && (
            <>
              <dt>몸무게</dt>
              <dd>{player.weight} kg</dd>
            </>
          )}
          {player.age_stage && (
            <>
              <dt>나이</dt>
              <dd>{player.age_stage}세</dd>
            </>
          )}
          {player.peak_age != null && (
            <>
              <dt>전성기 참고</dt>
              <dd>{player.peak_age}세</dd>
            </>
          )}
        </dl>
      </section>

      <section className="stats-grid">
        <div>
          <h4>포지션 적정</h4>
          <PositionFitGrid fit={player.position_fit} />
        </div>
        <div>
          <h4>능력치</h4>
          <dl className="stat-list">
            <dt>스피드</dt><dd>{player.speed}</dd>
            <dt>파워</dt><dd>{player.power}</dd>
            <dt>기술</dt><dd>{player.technique}</dd>
            <dt>슈팅</dt><dd>{player.shooting}</dd>
            <dt>패스</dt><dd>{player.passing}</dd>
            <dt>활동량</dt><dd>{player.stamina}</dd>
            <dt>리더십</dt><dd>{player.leadership}</dd>
          </dl>
        </div>
      </section>

      {player.comment && (
        <section>
          <h4>코멘트</h4>
          <p className="comment">{player.comment}</p>
        </section>
      )}

      {onSaveComment && (
        <section>
          <h4>코멘트 수정</h4>
          <CommentEditor initial={player.comment ?? ''} onSave={onSaveComment} />
        </section>
      )}
    </div>
  );
}

function CommentEditor({
  initial,
  onSave,
}: {
  initial: string;
  onSave: (c: string) => Promise<void>;
}) {
  return (
    <form
      onSubmit={async (e) => {
        e.preventDefault();
        const fd = new FormData(e.currentTarget);
        await onSave(String(fd.get('comment') ?? ''));
      }}
    >
      <textarea name="comment" defaultValue={initial} rows={4} className="input" />
      <button type="submit" className="btn btn-primary" style={{ marginTop: 8 }}>
        저장
      </button>
    </form>
  );
}
