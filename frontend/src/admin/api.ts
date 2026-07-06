/** Empty string = same origin (Vite/nginx proxy /api → backend). */
import { tStatic } from './i18n';

const API = import.meta.env.VITE_API_BASE_URL ?? '';

export type AuthResponse = {
  accessToken: string;
  refreshToken: string;
  user: { id: string; username: string; email: string; fullName: string; role: string };
};

export type DashboardStat = {
  key: string;
  label: string;
  count: number;
  changePercent: number;
  iconColor: string;
};

export type ArticleAuthor = { id: string; fullName: string; avatarUrl?: string };

export type ArticleListItem = {
  id: string;
  title: string;
  slug: string;
  category: string;
  categoryLabel: string;
  status: string;
  statusLabel: string;
  thumbnailUrl?: string;
  author: ArticleAuthor;
  createdAt: string;
  publishedAt?: string;
};

export type PaginatedArticles = {
  items: ArticleListItem[];
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
};

export type PopularDestination = {
  id: string;
  name: string;
  imageUrl?: string;
  viewCount: number;
  articleCount: number;
};

export type ActivityLog = {
  id: string;
  actionType: string;
  description: string;
  userName: string;
  userAvatarUrl?: string;
  createdAt: string;
};

export type PaginatedActivityLogs = {
  items: ActivityLog[];
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
};

export type Permission = { key: string; label: string; granted: boolean };

export type SearchResult = {
  entityType: string;
  id: string;
  title: string;
  subtitle?: string;
  imageUrl?: string;
};

export type Banner = {
  id: string;
  title: string;
  imageUrl: string;
  linkUrl?: string;
  sortOrder: number;
  isActive: boolean;
  region: string;
  createdAt: string;
};

export type GalleryImage = {
  id: string;
  title: string;
  imageUrl: string;
  destinationId?: string | null;
  destinationName?: string;
  sortOrder: number;
  createdAt: string;
};

export type InboxSummary = {
  pendingArticles: number;
  pendingComments: number;
};

export type FeaturedContent = {
  id: string;
  title: string;
  subtitle?: string;
  imageUrl?: string;
  linkUrl?: string;
  contentType: string;
  isActive: boolean;
  sortOrder: number;
  createdAt: string;
};

export type AdminDestination = {
  id: string;
  name: string;
  province: string;
  region: string;
  category: string;
  imageUrl?: string;
  estimatedCost: number;
  articleCount: number;
};

export type ArticleDetail = {
  id: string;
  title: string;
  slug: string;
  summary?: string;
  content: string;
  articleType: string;
  category: string;
  status: string;
  thumbnailUrl?: string;
  destinationId?: string;
  viewCount: number;
  author: ArticleAuthor;
  createdAt: string;
  updatedAt?: string;
  publishedAt?: string;
};

export type ArticlePayload = {
  title: string;
  slug: string;
  summary?: string | null;
  content: string;
  articleType: string;
  category: string;
  status: string;
  thumbnailUrl?: string | null;
  destinationId?: string | null;
};

export type AdminDestinationDetail = {
  id: string;
  name: string;
  slug: string;
  description: string;
  province: string;
  region: string;
  latitude: number;
  longitude: number;
  category: string;
  estimatedCost: number;
  imageUrl?: string;
  isActive: boolean;
  articleCount: number;
};

export type DestinationPayload = {
  name: string;
  slug: string;
  description: string;
  province: string;
  region: string;
  latitude: number;
  longitude: number;
  category: string;
  estimatedCost: number;
  imageUrl?: string | null;
};

export type AdminUser = {
  id: string;
  username: string;
  email: string;
  fullName: string;
  role: string;
  isActive: boolean;
  createdAt: string;
};

export type CreateAdminUserPayload = {
  username: string;
  email: string;
  password: string;
  fullName: string;
  role: string;
};

export type PendingComment = {
  id: string;
  destinationId: string;
  destinationName: string;
  userId: string;
  username: string;
  fullName: string;
  rating: number;
  content?: string;
  createdAt: string;
  updatedAt?: string;
};

export type BannerPayload = {
  title: string;
  imageUrl: string;
  linkUrl?: string | null;
  sortOrder: number;
  isActive: boolean;
  region: string;
};

export type GalleryPayload = {
  title: string;
  imageUrl: string;
  destinationId?: string | null;
  sortOrder: number;
};

export type FeaturedPayload = {
  title: string;
  subtitle?: string | null;
  imageUrl?: string | null;
  linkUrl?: string | null;
  contentType: string;
  isActive: boolean;
  sortOrder: number;
};

let onUnauthorized: (() => void) | null = null;

export function setAdminUnauthorizedHandler(handler: () => void) {
  onUnauthorized = handler;
}

function persistAuth(data: AuthResponse) {
  localStorage.setItem('admin_token', data.accessToken);
  localStorage.setItem('admin_auth', JSON.stringify(data));
}

async function refreshAccessToken(): Promise<string | null> {
  const saved = localStorage.getItem('admin_auth');
  if (!saved) return null;
  try {
    const auth = JSON.parse(saved) as AuthResponse;
    const res = await fetch(`${API}/api/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: auth.refreshToken }),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as AuthResponse;
    persistAuth(data);
    return data.accessToken;
  } catch {
    return null;
  }
}

function parseErrorMessage(status: number, path: string, text: string): string {
  if (status === 404) {
    return `Không tìm thấy API (${path}). Hãy khởi động lại backend.`;
  }
  if (status === 401) return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  try {
    const json = JSON.parse(text) as { message?: string; title?: string };
    return json.message || json.title || text || 'Yêu cầu thất bại';
  } catch {
    return text || 'Yêu cầu thất bại';
  }
}

async function request<T>(path: string, options: RequestInit = {}, retried = false): Promise<T> {
  const token = localStorage.getItem('admin_token') || localStorage.getItem('token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  let res: Response;
  try {
    res = await fetch(`${API}${path}`, { ...options, headers });
  } catch {
    throw new Error(tStatic('errors.network'));
  }

  if (res.status === 401 && !retried && !path.endsWith('/login')) {
    const newToken = await refreshAccessToken();
    if (newToken) return request<T>(path, options, true);
    onUnauthorized?.();
    throw new Error(tStatic('errors.sessionExpired'));
  }

  if (!res.ok) {
    const text = await res.text();
    throw new Error(parseErrorMessage(res.status, path, text));
  }
  if (res.status === 204) return undefined as T;

  const text = await res.text();
  return (text ? JSON.parse(text) : undefined) as T;
}

export const adminApi = {
  login: async (username: string, password: string) => {
    const data = await request<AuthResponse>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    });
    persistAuth(data);
    return data;
  },
  logout: () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_auth');
  },
  getAuth: (): AuthResponse | null => {
    const saved = localStorage.getItem('admin_auth');
    return saved ? JSON.parse(saved) : null;
  },
  dashboardStats: () => request<{ stats: DashboardStat[] }>('/api/content/dashboard/stats'),
  recentArticles: (page = 1, pageSize = 3) =>
    request<PaginatedArticles>(`/api/content/dashboard/recent-articles?page=${page}&pageSize=${pageSize}`),
  popularDestinations: (limit = 5) =>
    request<PopularDestination[]>(`/api/content/dashboard/popular-destinations?limit=${limit}`),
  recentActivity: (limit = 6) =>
    request<ActivityLog[]>(`/api/content/dashboard/recent-activity?limit=${limit}`),
  activityLogs: (params?: { page?: number; pageSize?: number }) => {
    const q = new URLSearchParams();
    if (params?.page) q.set('page', String(params.page));
    if (params?.pageSize) q.set('pageSize', String(params.pageSize));
    return request<PaginatedActivityLogs>(`/api/content/dashboard/activity?${q}`);
  },
  permissions: () =>
    request<{ role: string; canPublish: boolean; permissions: Permission[] }>(
      '/api/content/dashboard/permissions',
    ),
  inboxSummary: () =>
    request<InboxSummary>('/api/content/dashboard/inbox'),
  search: (q: string) => request<{ results: SearchResult[] }>(`/api/content/dashboard/search?q=${encodeURIComponent(q)}`),
  articles: (params?: { page?: number; pageSize?: number; status?: string; articleType?: string }) => {
    const q = new URLSearchParams();
    if (params?.page) q.set('page', String(params.page));
    if (params?.pageSize) q.set('pageSize', String(params.pageSize));
    if (params?.status) q.set('status', params.status);
    if (params?.articleType) q.set('articleType', params.articleType);
    return request<PaginatedArticles>(`/api/content/articles?${q}`);
  },
  banners: () => request<Banner[]>('/api/content/banners'),
  gallery: () => request<GalleryImage[]>('/api/content/gallery'),
  featured: () => request<FeaturedContent[]>('/api/content/featured'),
  adminDestinations: (params?: { region?: string; category?: string }) => {
    const q = new URLSearchParams();
    if (params?.region) q.set('region', params.region);
    if (params?.category) q.set('category', params.category);
    return request<AdminDestination[]>(`/api/content/destinations?${q}`);
  },
  getArticle: (id: string) => request<ArticleDetail>(`/api/content/articles/${id}`),
  createArticle: (body: ArticlePayload) =>
    request<ArticleDetail>('/api/content/articles', {
      method: 'POST',
      body: JSON.stringify(body),
    }),
  updateArticle: (id: string, body: Partial<ArticlePayload>) =>
    request<ArticleDetail>(`/api/content/articles/${id}`, {
      method: 'PUT',
      body: JSON.stringify(body),
    }),
  publishArticle: (id: string) =>
    request<void>(`/api/content/articles/${id}/publish`, { method: 'PATCH' }),
  updateArticleStatus: (id: string, status: string) =>
    request<ArticleDetail>(`/api/content/articles/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ status }),
    }),
  deleteArticle: (id: string) =>
    request<void>(`/api/content/articles/${id}`, { method: 'DELETE' }),
  uploadMedia: async (file: File): Promise<string> => {
    const token = localStorage.getItem('admin_token') || localStorage.getItem('token');
    const form = new FormData();
    form.append('file', file);
    let res: Response;
    try {
      res = await fetch(`${API}/api/content/media/upload`, {
        method: 'POST',
        headers: token ? { Authorization: `Bearer ${token}` } : {},
        body: form,
      });
    } catch {
      throw new Error('Không kết nối được máy chủ upload.');
    }
    if (res.status === 401) {
      const newToken = await refreshAccessToken();
      if (newToken) return adminApi.uploadMedia(file);
      onUnauthorized?.();
      throw new Error('Phiên đăng nhập đã hết hạn.');
    }
    if (!res.ok) {
      const text = await res.text();
      throw new Error(parseErrorMessage(res.status, '/api/content/media/upload', text));
    }
    const data = (await res.json()) as { url: string };
    return data.url;
  },
  createBanner: (body: BannerPayload) =>
    request<Banner>('/api/content/banners', { method: 'POST', body: JSON.stringify(body) }),
  updateBanner: (id: string, body: Partial<BannerPayload>) =>
    request<Banner>(`/api/content/banners/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  deleteBanner: (id: string) =>
    request<void>(`/api/content/banners/${id}`, { method: 'DELETE' }),
  createGallery: (body: GalleryPayload) =>
    request<GalleryImage>('/api/content/gallery', { method: 'POST', body: JSON.stringify(body) }),
  updateGallery: (id: string, body: Partial<GalleryPayload>) =>
    request<GalleryImage>(`/api/content/gallery/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  deleteGallery: (id: string) =>
    request<void>(`/api/content/gallery/${id}`, { method: 'DELETE' }),
  createFeatured: (body: FeaturedPayload) =>
    request<FeaturedContent>('/api/content/featured', { method: 'POST', body: JSON.stringify(body) }),
  updateFeatured: (id: string, body: Partial<FeaturedPayload>) =>
    request<FeaturedContent>(`/api/content/featured/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  deleteFeatured: (id: string) =>
    request<void>(`/api/content/featured/${id}`, { method: 'DELETE' }),
  getDestination: (id: string) =>
    request<AdminDestinationDetail>(`/api/content/destinations/${id}`),
  createDestination: (body: DestinationPayload) =>
    request<{ id: string }>('/api/manager/destinations', {
      method: 'POST',
      body: JSON.stringify({
        ...body,
        openingHours: null,
        bestTimeToVisit: null,
        suitableWeather: null,
        travelStyle: null,
        aiRecommendationNote: null,
        embeddingText: null,
      }),
    }),
  updateDestination: (id: string, body: Partial<DestinationPayload & { isActive?: boolean }>) =>
    request<unknown>(`/api/manager/destinations/${id}`, {
      method: 'PUT',
      body: JSON.stringify(body),
    }),
  deleteDestination: (id: string) =>
    request<void>(`/api/manager/destinations/${id}`, { method: 'DELETE' }),
  inactiveDestinations: () => request<AdminDestination[]>('/api/content/destinations/inactive'),
  restoreDestination: (id: string) =>
    request<void>(`/api/manager/destinations/${id}/restore`, { method: 'PATCH' }),
  bulkPublishArticles: (ids: string[]) =>
    request<{ published: number }>('/api/content/articles/bulk-publish', {
      method: 'POST',
      body: JSON.stringify({ ids }),
    }),
  pendingComments: () => request<PendingComment[]>('/api/manager/comments/pending'),
  approveComment: (id: string) =>
    request<void>(`/api/manager/comments/${id}/approve`, { method: 'PATCH' }),
  rejectComment: (id: string) =>
    request<void>(`/api/manager/comments/${id}/reject`, { method: 'PATCH' }),
  adminUsers: () => request<AdminUser[]>('/api/admin/users'),
  createAdminUser: (body: CreateAdminUserPayload) =>
    request<AdminUser>('/api/admin/users', { method: 'POST', body: JSON.stringify(body) }),
  updateUserRole: (id: string, role: string) =>
    request<void>(`/api/admin/users/${id}/role`, {
      method: 'PATCH',
      body: JSON.stringify({ role }),
    }),
  toggleUserActive: (id: string) =>
    request<void>(`/api/admin/users/${id}/toggle-active`, { method: 'PATCH' }),
  updateAdminUser: (id: string, body: Partial<CreateAdminUserPayload>) =>
    request<AdminUser>(`/api/admin/users/${id}`, {
      method: 'PUT',
      body: JSON.stringify(body),
    }),
};

export function formatViewCount(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return String(n);
}

export function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Vừa xong';
  if (mins < 60) return `${mins} phút trước`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} giờ trước`;
  const days = Math.floor(hours / 24);
  return `${days} ngày trước`;
}

export function adminNavigate(route: string) {
  const path = route.startsWith('/admin') ? route : `/admin/${route.replace(/^\//, '')}`;
  window.history.pushState(null, '', path);
  window.dispatchEvent(new PopStateEvent('popstate'));
}

export function parseAdminRoute(): string {
  const match = window.location.pathname.match(/^\/admin\/?(.*)$/);
  const segment = match?.[1]?.replace(/\/$/, '') ?? '';
  return segment || 'dashboard';
}

export function adminModuleFromRoute(route: string): string {
  return route.split('/')[0] || 'dashboard';
}
