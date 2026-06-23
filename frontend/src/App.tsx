import { useEffect, useState } from 'react';
import { api, AuthResponse, Destination, FavoriteDestination } from './api';

type Tab = 'explore' | 'saved' | 'ai' | 'trips';

export default function App() {
  const [auth, setAuth] = useState<AuthResponse | null>(null);
  const [tab, setTab] = useState<Tab>('explore');
  const [destinations, setDestinations] = useState<Destination[]>([]);
  const [favorites, setFavorites] = useState<FavoriteDestination[]>([]);
  const [schedules, setSchedules] = useState<unknown[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [aiResult, setAiResult] = useState<unknown>(null);

  const [loginForm, setLoginForm] = useState({ username: 'traveler', password: 'Traveler@123' });
  const [aiForm, setAiForm] = useState({
    latitude: 10.7769,
    longitude: 106.7009,
    locationName: 'TP. Ho Chi Minh',
    budgetInput: 2000000,
    totalDays: 3,
    preferenceInput: 'thien nhien, mat me, chup anh',
  });

  useEffect(() => {
    const saved = localStorage.getItem('auth');
    if (saved) setAuth(JSON.parse(saved));
  }, []);

  useEffect(() => {
    if (!auth) return;
    localStorage.setItem('token', auth.accessToken);
    loadExplore();
  }, [auth]);

  const withFavoriteState = (items: Destination[], saved: FavoriteDestination[]) => {
    const savedIds = new Set(saved.map((f) => f.destination.id));
    return items.map((d) => ({ ...d, isFavorite: savedIds.has(d.id) }));
  };

  const loadExplore = async () => {
    try {
      const canLoadFavorites = auth?.user.role === 'Traveler' || auth?.user.role === 'Admin';
      const [items, saved] = await Promise.all([
        api.destinations(),
        canLoadFavorites ? api.favorites() : Promise.resolve([]),
      ]);
      setFavorites(saved);
      setDestinations(withFavoriteState(items, saved));
    } catch (e) {
      setError((e as Error).message);
    }
  };

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

  const loadFavorites = async () => {
    if (auth?.user.role !== 'Traveler' && auth?.user.role !== 'Admin') return;
    try {
      const saved = await api.favorites();
      setFavorites(saved);
      setDestinations((items) => withFavoriteState(items, saved));
    } catch (e) {
      setError((e as Error).message);
    }
  };

  const toggleFavorite = async (destination: Destination) => {
    setError('');
    try {
      if (destination.isFavorite) {
        await api.deleteFavorite(destination.id);
      } else {
        await api.addFavorite(destination.id);
      }
      const saved = await api.favorites();
      setFavorites(saved);
      setDestinations((items) => withFavoriteState(items, saved));
    } catch (e) {
      setError((e as Error).message);
    }
  };

  if (!auth) {
    return (
      <div className="app">
        <header><span className="logo">VietAI Travel</span></header>
        <div className="card" style={{ maxWidth: 400, margin: '40px auto' }}>
          <h2>Dang nhap</h2>
          <p style={{ color: 'var(--muted)', fontSize: 14 }}>
            Traveler: traveler / Traveler@123 - Manager: manager / Manager@123 - Admin: admin / Admin@123
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
            {loading ? 'Dang dang nhap...' : 'Dang nhap'}
          </button>
        </div>
      </div>
    );
  }

  const canUseAi = auth.user.role === 'Traveler' || auth.user.role === 'Admin';
  const canUseFavorites = auth.user.role === 'Traveler' || auth.user.role === 'Admin';

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
            Dang xuat
          </button>
        </div>
      </header>

      <div className="tabs">
        {(['explore', 'saved', 'ai', 'trips'] as Tab[]).map((t) => (
          <button
            key={t}
            className={tab === t ? 'active' : ''}
            disabled={(t === 'ai' && !canUseAi) || (t === 'saved' && !canUseFavorites)}
            title={
              t === 'ai' && !canUseAi
                ? 'AI Planner chi danh cho Traveler hoac Admin'
                : t === 'saved' && !canUseFavorites
                  ? 'Saved chi danh cho Traveler hoac Admin'
                  : undefined
            }
            onClick={() => {
              setError('');
              setTab(t);
              if (t === 'explore') loadExplore();
              if (t === 'saved') loadFavorites();
              if (t === 'trips') loadTrips();
            }}
          >
            {t === 'explore'
              ? 'Explore'
              : t === 'saved'
                ? 'Saved'
                : t === 'ai'
                  ? 'AI Planner'
                  : 'My Trips'}
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
              <p style={{ fontSize: 13, color: 'var(--muted)' }}>{d.province} - {d.category}</p>
              <p style={{ fontSize: 13, color: 'var(--muted)' }}>
                Rating: {d.averageRating.toFixed(1)} ({d.totalReviews} reviews)
              </p>
              <p style={{ fontSize: 13 }}>{d.description.slice(0, 100)}...</p>
              <strong style={{ color: 'var(--primary)' }}>{d.estimatedCost.toLocaleString()} VND</strong>
              {canUseFavorites && (
                <button
                  className={d.isFavorite ? 'secondary' : undefined}
                  onClick={() => toggleFavorite(d)}
                  style={{ marginTop: 12 }}
                >
                  {d.isFavorite ? 'Bo luu' : 'Luu dia diem'}
                </button>
              )}
            </div>
          ))}
        </div>
      )}

      {tab === 'saved' && (
        <div className="grid">
          {favorites.length === 0 ? (
            <div className="card">
              <h2>Saved Places</h2>
              <p style={{ color: 'var(--muted)' }}>Chua co dia diem da luu.</p>
            </div>
          ) : (
            favorites.map((f) => (
              <div key={f.id} className="card dest">
                {f.destination.imageUrl && (
                  <img src={f.destination.imageUrl} alt={f.destination.name} />
                )}
                <h3>{f.destination.name}</h3>
                <p style={{ fontSize: 13, color: 'var(--muted)' }}>
                  {f.destination.province} - {f.destination.category}
                </p>
                <p style={{ fontSize: 13 }}>{f.destination.description.slice(0, 100)}...</p>
                <strong style={{ color: 'var(--primary)' }}>
                  {f.destination.estimatedCost.toLocaleString()} VND
                </strong>
                <button
                  className="secondary"
                  onClick={() => toggleFavorite({ ...f.destination, isFavorite: true })}
                  style={{ marginTop: 12 }}
                >
                  Bo luu
                </button>
              </div>
            ))
          )}
        </div>
      )}

      {tab === 'ai' && (
        <div className="card">
          <h2>AI Itinerary</h2>
          {!canUseAi && (
            <p className="error">AI Planner chi danh cho Traveler hoac Admin. Hay dang xuat va dang nhap bang traveler / Traveler@123.</p>
          )}
          <p style={{ color: 'var(--muted)' }}>
            Goi y dua tren vi tri, thoi tiet, pgvector va Ollama local.
          </p>
          <input value={aiForm.locationName} onChange={(e) => setAiForm({ ...aiForm, locationName: e.target.value })} placeholder="Vi tri" />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            <input type="number" step="0.0001" value={aiForm.latitude} onChange={(e) => setAiForm({ ...aiForm, latitude: +e.target.value })} placeholder="Latitude" />
            <input type="number" step="0.0001" value={aiForm.longitude} onChange={(e) => setAiForm({ ...aiForm, longitude: +e.target.value })} placeholder="Longitude" />
          </div>
          <input type="number" value={aiForm.budgetInput} onChange={(e) => setAiForm({ ...aiForm, budgetInput: +e.target.value })} placeholder="Ngan sach (VND)" />
          <input type="number" value={aiForm.totalDays} onChange={(e) => setAiForm({ ...aiForm, totalDays: +e.target.value })} placeholder="So ngay" />
          <textarea rows={3} value={aiForm.preferenceInput} onChange={(e) => setAiForm({ ...aiForm, preferenceInput: e.target.value })} placeholder="So thich" />
          <button className="gradient" onClick={handleRecommend} disabled={loading || !canUseAi}>
            {loading ? 'AI dang tao lich trinh...' : 'Tao lich trinh AI'}
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
            <p style={{ color: 'var(--muted)' }}>Chua co lich trinh. Dung AI Planner de tao.</p>
          ) : (
            <pre style={{ fontSize: 13 }}>{JSON.stringify(schedules, null, 2)}</pre>
          )}
        </div>
      )}
    </div>
  );
}
