import { NavLink, Outlet, Link } from 'react-router-dom';

export default function Layout() {
  return (
    <div className="app">
      <header className="app-header">
        <div className="app-header-inner">
          <h1>
            <Link to="/admin">Again26 매니저</Link>
          </h1>
          <nav className="tabs">
            <NavLink to="/admin" end className={({ isActive }) => (isActive ? 'tab active' : 'tab')}>
              선수
            </NavLink>
            <NavLink to="/admin/formations" className={({ isActive }) => (isActive ? 'tab active' : 'tab')}>
              포메이션
            </NavLink>
            <NavLink to="/admin/key-positions" className={({ isActive }) => (isActive ? 'tab active' : 'tab')}>
              키포지션
            </NavLink>
          </nav>
          <a href={import.meta.env.BASE_URL} className="home-link">
            게임 홈
          </a>
        </div>
      </header>
      <main className="app-main">
        <Outlet />
      </main>
    </div>
  );
}
