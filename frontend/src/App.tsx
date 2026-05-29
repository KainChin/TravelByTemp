import { useEffect, useState } from 'react';
import { api, AuthResponse, Destination } from './api';

type Tab = 'explore' | 'ai' | 'trips';

export default function App() {
  const [auth, setAuth] = useState<AuthResponse | null>(null);
  const [tab, setTab] = useState<Tab>('explore');
  const [destinations, setDestinations] = useState<Destination[]>([]);
  const [schedules, setSchedules] = useState<unknown[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [aiResult, setAiResult] = useState<unknown>(null);

  const [loginForm, setLoginForm] = useState({ username: 'traveler', password: 'Traveler@123' });
  const [aiForm, setAiForm] = useState({
    latitude: 10.7769,
    longitude: 106.7009,
    locationName: 'TP. Hồ Chí Minh',
    budgetInput: 2000000,
    totalDays: 3,
    preferenceInput: 'thiên nhiên, mát mẻ, chụp ảnh',
  });

  useEffect(() => {
    const saved = localStorage.getItem('auth');
    if (saved) setAuth(JSON.parse(saved));
  }, []);

  useEffect(() => {
    if (!auth) return;
    localStorage.setItem('token', auth.accessToken);
    api.destinations().then(setDestinations).catch((e) => setError(e.message));
  }, [auth]);

  const handleLogin = async () => {
    setError('');
    setLoading(true);
    try {
      const res = await api.login(loginForm.username, loginForm.password);
      setAuth(res);
      localStorage.setItem('auth', JSON.stringify(res));
      localStorage.setItem('token', res.accessToken);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  };

  const handleRecommend = async () => {
    setError('');
    setLoading(true);
    try {
      const res = await api.recommend(aiForm);
      setAiResult(res);
      setTab('trips');
      const list = await api.schedules();
      setSchedules(list);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  };

  const loadTrips = async () => {
    try {
      setSchedules(await api.schedules());
    } catch (e) {
      setError((e as Error).message);
    }
  };

  if (!auth) {
    return (
      <div className="app">
        <header><span className="logo">VietAI Travel</span></header>
        <div className="card" style={{ maxWidth: 400, margin: '40px auto' }}>
          <h2>Đăng nhập</h2>
          <p style={{ color: 'var(--muted)', fontSize: 14 }}>
            Traveler: traveler / Traveler@123 · Manager: manager / Manager@123 · Admin: admin / Admin@123
          </p>
          <input
            placeholder="Username"
            value={loginForm.username}
            onChange={(e) => setLoginForm({ ...loginForm, username: e.target.value })}
          />
          <input
            type="password"
            placeholder="Password"
            value={loginForm.password}
            onChange={(e) => setLoginForm({ ...loginForm, password: e.target.value })}
          />
          {error && <p className="error">{error}</p>}
          <button onClick={handleLogin} disabled={loading}>
            {loading ? 'Đang đăng nhập...' : 'Đăng nhập'}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="app">
      <header>
        <span className="logo">VietAI Travel</span>
        <div>
          <span className="badge">{auth.user.role}</span>
          <span style={{ marginLeft: 12 }}>{auth.user.fullName}</span>
          <button
            className="secondary"
            style={{ width: 'auto', marginLeft: 12 }}
            onClick={() => {
              localStorage.clear();
              setAuth(null);
            }}
          >
            Đăng xuất
          </button>
        </div>
      </header>

      <div className="tabs">
        {(['explore', 'ai', 'trips'] as Tab[]).map((t) => (
          <button key={t} className={tab === t ? 'active' : ''} onClick={() => { setTab(t); if (t === 'trips') loadTrips(); }}>
            {t === 'explore' ? 'Explore' : t === 'ai' ? 'AI Planner' : 'My Trips'}
          </button>
        ))}
      </div>

      {error && <p className="error">{error}</p>}

      {tab === 'explore' && (
        <div className="grid">
          {destinations.map((d) => (
            <div key={d.id} className="card dest">
              {d.imageUrl && <img src={d.imageUrl} alt={d.name} />}
              <h3>{d.name}</h3>
              <p style={{ fontSize: 13, color: 'var(--muted)' }}>{d.province} · {d.category}</p>
              <p style={{ fontSize: 13 }}>{d.description.slice(0, 100)}...</p>
              <strong style={{ color: 'var(--primary)' }}>{d.estimatedCost.toLocaleString()} VND</strong>
            </div>
          ))}
        </div>
      )}

      {tab === 'ai' && (
        <div className="card">
          <h2>AI Itinerary — Just for You ✨</h2>
          <p style={{ color: 'var(--muted)' }}>
            Gợi ý dựa trên vị trí, thời tiết (Open-Meteo), pgvector + Ollama local — không dùng LLM thương mại.
          </p>
          <input value={aiForm.locationName} onChange={(e) => setAiForm({ ...aiForm, locationName: e.target.value })} placeholder="Vị trí" />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            <input type="number" step="0.0001" value={aiForm.latitude} onChange={(e) => setAiForm({ ...aiForm, latitude: +e.target.value })} placeholder="Latitude" />
            <input type="number" step="0.0001" value={aiForm.longitude} onChange={(e) => setAiForm({ ...aiForm, longitude: +e.target.value })} placeholder="Longitude" />
          </div>
          <input type="number" value={aiForm.budgetInput} onChange={(e) => setAiForm({ ...aiForm, budgetInput: +e.target.value })} placeholder="Ngân sách (VND)" />
          <input type="number" value={aiForm.totalDays} onChange={(e) => setAiForm({ ...aiForm, totalDays: +e.target.value })} placeholder="Số ngày" />
          <textarea rows={3} value={aiForm.preferenceInput} onChange={(e) => setAiForm({ ...aiForm, preferenceInput: e.target.value })} placeholder="Sở thích" />
          <button className="gradient" onClick={handleRecommend} disabled={loading}>
            {loading ? 'AI đang tạo lịch trình...' : 'Tạo lịch trình AI'}
          </button>
          {aiResult && (
            <pre style={{ background: '#f0f0f0', padding: 12, borderRadius: 12, overflow: 'auto', fontSize: 12 }}>
              {JSON.stringify(aiResult, null, 2)}
            </pre>
          )}
        </div>
      )}

      {tab === 'trips' && (
        <div className="card">
          <h2>My Trips</h2>
          {schedules.length === 0 ? (
            <p style={{ color: 'var(--muted)' }}>Chưa có lịch trình. Dùng AI Planner để tạo.</p>
          ) : (
            <pre style={{ fontSize: 13 }}>{JSON.stringify(schedules, null, 2)}</pre>
          )}
        </div>
      )}
    </div>
  );
}
