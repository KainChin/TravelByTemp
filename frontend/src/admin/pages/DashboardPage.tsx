import type { CSSProperties } from 'react';
import { useEffect, useState } from 'react';
import {
  adminApi,
  adminNavigate,
  ActivityLog,
  ArticleListItem,
  DashboardStat,
  formatViewCount,
  PaginatedArticles,
  Permission,
  PopularDestination,
} from '../api';
import { CategoryTag, StatusTag } from '../components/ContentTags';
import { ActivityTimeline } from '../components/ActivityTimeline';
import { useArticleMenuItems } from '../hooks/useArticleMenuItems';
import { useI18n } from '../i18n';
import { RowActionMenu } from '../components/RowActionMenu';
import {
  CheckIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  EyeIcon,
  MapPinIcon,
  PenLineIcon,
  ShieldCheckIcon,
  STAT_ICON_MAP,
  TrendingDownIcon,
  TrendingUpIcon,
} from '../components/Icons';

function StatCard({
  stat,
  index,
  onNavigate,
}: {
  stat: DashboardStat;
  index: number;
  onNavigate?: (route: string) => void;
}) {
  const { t, formatNumber } = useI18n();
  const Icon = STAT_ICON_MAP[stat.key as keyof typeof STAT_ICON_MAP] ?? STAT_ICON_MAP.totalArticles;
  const TrendIcon = stat.changePercent >= 0 ? TrendingUpIcon : TrendingDownIcon;
  const labelKey = `dashboard.stats.${stat.key}`;
  const label = t(labelKey) === labelKey ? stat.label : t(labelKey);
  const routeMap: Record<string, string> = {
    totalArticles: 'articles',
    travelNews: 'news',
    destinations: 'destinations',
    pending: 'review',
  };
  const targetRoute = routeMap[stat.key];

  return (
    <div
      className={`stat-card stat-${stat.iconColor} stat-enter${targetRoute && onNavigate ? ' stat-clickable' : ''}`}
      style={{ '--stagger': index } as CSSProperties}
      role={targetRoute && onNavigate ? 'button' : undefined}
      tabIndex={targetRoute && onNavigate ? 0 : undefined}
      onClick={targetRoute && onNavigate ? () => onNavigate(targetRoute) : undefined}
      onKeyDown={
        targetRoute && onNavigate
          ? (e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                onNavigate(targetRoute);
              }
            }
          : undefined
      }
    >
      <div className="stat-icon">
        <Icon size={20} />
      </div>
      <div className="stat-body">
        <span className="stat-label">{label}</span>
        <span className="stat-value">{formatNumber(stat.count)}</span>
        <span className={`stat-change${stat.changePercent >= 0 ? ' up' : ' down'}`}>
          <TrendIcon size={14} />
          {t('common.changeVsLastMonth', { percent: Math.abs(stat.changePercent) })}
        </span>
      </div>
    </div>
  );
}

function RecentArticlesTable({
  data,
  page,
  onPageChange,
  openMenuId,
  setOpenMenuId,
  onToast,
}: {
  data: PaginatedArticles | null;
  page: number;
  onPageChange: (p: number) => void;
  openMenuId: string | null;
  setOpenMenuId: (id: string | null) => void;
  onToast: (msg: string) => void;
}) {
  const { t, formatNumber } = useI18n();
  const buildMenuItems = useArticleMenuItems();

  if (!data) return <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>;

  const start = (data.page - 1) * data.pageSize + 1;
  const end = Math.min(data.page * data.pageSize, data.totalCount);

  return (
    <>
      <div className="table-wrap">
        <table className="admin-table">
          <thead>
            <tr>
              <th>{t('table.title')}</th>
              <th>{t('table.category')}</th>
              <th>{t('table.author')}</th>
              <th>{t('table.status')}</th>
              <th aria-label={t('common.actions')} />
            </tr>
          </thead>
          <tbody>
            {data.items.map((row: ArticleListItem, i) => (
              <tr key={row.id} className="table-row-enter" style={{ '--row-i': i } as CSSProperties}>
                <td>
                  <div className="article-title-cell">
                    {row.thumbnailUrl && (
                      <img src={row.thumbnailUrl} alt="" className="article-thumb" />
                    )}
                    <span>{row.title}</span>
                  </div>
                </td>
                <td>
                  <CategoryTag category={row.category} />
                </td>
                <td>
                  <div className="author-cell">
                    <img
                      src={row.author.avatarUrl ?? `https://i.pravatar.cc/32?u=${row.author.id}`}
                      alt=""
                      className="author-avatar"
                    />
                    <span>{row.author.fullName}</span>
                  </div>
                </td>
                <td>
                  <StatusTag status={row.status} />
                </td>
                <td className="col-actions">
                  <RowActionMenu
                    open={openMenuId === row.id}
                    onToggle={() => setOpenMenuId(openMenuId === row.id ? null : row.id)}
                    onClose={() => setOpenMenuId(null)}
                    items={buildMenuItems(row, { onNotify: onToast })}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="table-footer">
        <span>
          {t('common.showingRangeArticles', {
            start,
            end,
            total: formatNumber(data.totalCount),
          })}
        </span>
        <div className="pagination">
          <button type="button" className="icon-btn" disabled={page <= 1} onClick={() => onPageChange(page - 1)} aria-label={t('common.prevPage')}>
            <ChevronLeftIcon size={16} />
          </button>
          {Array.from({ length: Math.min(5, data.totalPages) }, (_, i) => i + 1).map((p) => (
            <button
              key={p}
              type="button"
              className={p === page ? 'active' : ''}
              onClick={() => onPageChange(p)}
            >
              {p}
            </button>
          ))}
          {data.totalPages > 5 && <span className="pagination-ellipsis">…</span>}
          {data.totalPages > 5 && (
            <button type="button" onClick={() => onPageChange(data.totalPages)}>
              {data.totalPages}
            </button>
          )}
          <button type="button" className="icon-btn" disabled={page >= data.totalPages} onClick={() => onPageChange(page + 1)} aria-label={t('common.nextPage')}>
            <ChevronRightIcon size={16} />
          </button>
        </div>
      </div>
    </>
  );
}

function PopularDestinations({ items }: { items: PopularDestination[] | null }) {
  const { t } = useI18n();
  if (!items) return <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>;

  return (
    <ul className="dest-list">
      {items.map((d, i) => (
        <li key={d.id} className="dest-item dest-enter" style={{ '--stagger': i } as CSSProperties}>
          {d.imageUrl && <img src={d.imageUrl} alt="" className="dest-thumb" />}
          <div className="dest-info">
            <span className="dest-name">{d.name}</span>
            <span className="dest-meta">
              <EyeIcon size={14} />
              {formatViewCount(d.viewCount)}
              <span className="dest-meta-sep">·</span>
              {t('common.articlesCount', { count: d.articleCount })}
            </span>
          </div>
        </li>
      ))}
    </ul>
  );
}

function PermissionsCard({ role, permissions }: { role: string; permissions: Permission[] | null }) {
  const { t } = useI18n();
  if (!permissions) return <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>;

  const roleLabel = role === 'Admin' ? t('roles.admin') : t('roles.contentManager');

  return (
    <>
      <div className="card-title-row">
        <ShieldCheckIcon size={18} />
        <h3 className="card-subtitle">{t('dashboard.permissions', { role: roleLabel })}</h3>
      </div>
      <ul className="perm-list">
        {permissions.filter((p) => p.granted).map((p, i) => {
          const permKey = `permissions.${p.key}`;
          const label = t(permKey) === permKey ? p.label : t(permKey);
          return (
          <li key={p.key} className="perm-enter" style={{ '--stagger': i } as CSSProperties}>
            <span className="perm-check">
              <CheckIcon size={14} />
            </span>
            {label}
          </li>
          );
        })}
      </ul>
    </>
  );
}

export function DashboardPage() {
  const { t } = useI18n();
  const [stats, setStats] = useState<DashboardStat[] | null>(null);
  const [articles, setArticles] = useState<PaginatedArticles | null>(null);
  const [destinations, setDestinations] = useState<PopularDestination[] | null>(null);
  const [activity, setActivity] = useState<ActivityLog[] | null>(null);
  const [permissions, setPermissions] = useState<{ role: string; permissions: Permission[] } | null>(null);
  const [page, setPage] = useState(1);
  const [error, setError] = useState('');
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);
  const [toast, setToast] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    adminApi
      .recentArticles(page, 3)
      .then(setArticles)
      .catch((e) => setError(e.message));
  }, [page, refreshKey]);

  const notify = (msg: string) => {
    setToast(msg);
    setRefreshKey((k) => k + 1);
  };

  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(t);
  }, [toast]);

  useEffect(() => {
    Promise.all([
      adminApi.dashboardStats(),
      adminApi.popularDestinations(5),
      adminApi.recentActivity(6),
      adminApi.permissions(),
    ])
      .then(([s, d, a, p]) => {
        setStats(s.stats);
        setDestinations(d);
        setActivity(a);
        setPermissions(p);
      })
      .catch((e) => setError(e.message));
  }, []);

  if (error) return <div className="admin-error">{error}</div>;

  return (
    <div className="dashboard-page">
      {toast && <div className="content-toast" role="status">{toast}</div>}
      <div className="page-header">
        <h1>{t('dashboard.title')}</h1>
        <p>{t('dashboard.description')}</p>
      </div>

      <div className="stats-grid">
        {stats
          ? stats.map((s, i) => (
              <StatCard key={s.key} stat={s} index={i} onNavigate={adminNavigate} />
            ))
          : Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="stat-card skeleton" />
            ))}
      </div>

      <div className="dashboard-grid">
        <div className="card card-wide card-enter" style={{ '--stagger': 0 } as CSSProperties}>
          <div className="card-header">
            <h2>{t('dashboard.recentArticles')}</h2>
            <button type="button" className="card-link" onClick={() => adminNavigate('articles')}>
              {t('common.viewAll')}
            </button>
          </div>
          <RecentArticlesTable
            data={articles}
            page={page}
            onPageChange={setPage}
            openMenuId={openMenuId}
            setOpenMenuId={setOpenMenuId}
            onToast={notify}
          />
        </div>

        <div className="card card-enter" style={{ '--stagger': 1 } as CSSProperties}>
          <div className="card-header">
            <h2>{t('dashboard.popularDestinations')}</h2>
            <button type="button" className="card-link" onClick={() => adminNavigate('destinations')}>
              {t('common.viewAll')}
            </button>
          </div>
          <PopularDestinations items={destinations} />
        </div>

        <div className="card card-enter" style={{ '--stagger': 2 } as CSSProperties}>
          <div className="card-header">
            <h2>{t('dashboard.recentActivity')}</h2>
          </div>
          <ActivityTimeline items={activity} />
          <button type="button" className="card-footer-link" onClick={() => adminNavigate('activity')}>
            {t('dashboard.allActivity')}
          </button>
        </div>

        <div className="card card-enter" style={{ '--stagger': 3 } as CSSProperties}>
          <PermissionsCard
            role={permissions?.role ?? 'Content Manager'}
            permissions={permissions?.permissions ?? null}
          />
        </div>
      </div>
    </div>
  );
}
