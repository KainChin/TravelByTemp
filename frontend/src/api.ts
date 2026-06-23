const API = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';

export type AuthResponse = {
  accessToken: string;
  refreshToken: string;
  user: { id: string; username: string; email: string; fullName: string; role: string };
};

export type Destination = {
  id: string;
  name: string;
  slug: string;
  description: string;
  province: string;
  region: string;
  category: string;
  estimatedCost: number;
  averageRating: number;
  totalReviews: number;
  imageUrl?: string;
  isFavorite?: boolean;
};

export type FavoriteDestination = {
  id: string;
  savedAt: string;
  destination: Destination;
};

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API}${path}`, { ...options, headers });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
  if (res.status === 204) return undefined as T;

  const text = await res.text();
  return (text ? JSON.parse(text) : undefined) as T;
}

export const api = {
  login: (username: string, password: string) =>
    request<AuthResponse>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    }),
  register: (username: string, email: string, password: string, fullName: string) =>
    request<AuthResponse>('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify({ username, email, password, fullName }),
    }),
  destinations: (params?: { region?: string; category?: string; maxBudget?: number }) => {
    const q = new URLSearchParams();
    if (params?.region) q.set('region', params.region);
    if (params?.category) q.set('category', params.category);
    if (params?.maxBudget) q.set('maxBudget', String(params.maxBudget));
    return request<Destination[]>(`/api/destinations?${q}`);
  },
  recommend: (body: {
    latitude: number;
    longitude: number;
    locationName?: string;
    budgetInput: number;
    totalDays: number;
    preferenceInput: string;
  }) =>
    request<unknown>('/api/ai/recommend', { method: 'POST', body: JSON.stringify(body) }),
  schedules: () => request<unknown[]>('/api/schedules'),
  favorites: () => request<FavoriteDestination[]>('/api/favorites'),
  addFavorite: (destinationId: string) =>
    request<FavoriteDestination>(`/api/favorites/${destinationId}`, { method: 'POST' }),
  deleteFavorite: (destinationId: string) =>
    request<void>(`/api/favorites/${destinationId}`, { method: 'DELETE' }),
};
