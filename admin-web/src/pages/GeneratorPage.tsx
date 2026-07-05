import { Link } from 'react-router-dom';
import { generatorPageUrl } from '../lib/paths';

export default function GeneratorPage() {
  const src = generatorPageUrl();

  return (
    <div className="generator-page">
      <div className="generator-bar">
        <Link to="/" className="btn btn-outline">
          ← 선수 목록
        </Link>
      </div>
      <iframe title="선수 생성기" src={src} className="generator-frame" />
    </div>
  );
}
