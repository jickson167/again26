import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { isSupabaseConfigured } from './lib/supabase';
import Layout from './pages/Layout';
import PlayersPage from './pages/PlayersPage';
import FormationsPage from './pages/FormationsPage';
import KeyPositionsPage from './pages/KeyPositionsPage';
import GeneratorPage from './pages/GeneratorPage';
import PlayerFormPage from './pages/PlayerFormPage';

export default function App() {
  if (!isSupabaseConfigured()) {
    return (
      <div className="setup">
        <h1>Supabase 설정 필요</h1>
        <p>
          <code>web/env.js</code>에 SUPABASE_URL과 SUPABASE_ANON_KEY가 있어야 합니다.
        </p>
      </div>
    );
  }

  return (
    <BrowserRouter basename={import.meta.env.BASE_URL.replace(/\/$/, '') || '/'}>
      <Routes>
        <Route element={<Layout />}>
          <Route index element={<PlayersPage />} />
          <Route path="formations" element={<FormationsPage />} />
          <Route path="key-positions" element={<KeyPositionsPage />} />
          <Route path="player-generator" element={<GeneratorPage />} />
          <Route path="players/new" element={<PlayerFormPage />} />
          <Route path="players/:id/edit" element={<PlayerFormPage />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
