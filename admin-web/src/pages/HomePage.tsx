import { Link } from 'react-router-dom';

export default function HomePage() {
  return (
    <div className="home-page">
      <div className="home-card">
        <h1>Again26 · 축구 매니저</h1>
        <p>선수·포메이션·키포지션 마스터 데이터를 관리하고 조회합니다.</p>
        <div className="home-actions">
          <Link to="/players" className="btn btn-primary">
            선수 목록
          </Link>
          <Link to="/admin" className="btn btn-outline">
            매니저 데이터 관리
          </Link>
        </div>
      </div>
    </div>
  );
}
