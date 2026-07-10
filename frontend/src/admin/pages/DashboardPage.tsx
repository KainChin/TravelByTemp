import type { CSSProperties } from 'react';
import { useEffect, useState } from 'react';
import {
  adminApi,
  adminNavigate,
  ActivityLog,
  DashboardStat,
  PaginatedArticles,
  PopularDestination,
  DashboardChartStats,
} from '../api';
import { useI18n } from '../i18n';
import { StatCard } from '../components/StatCard';
import { RecentArticlesTable } from '../components/RecentArticlesTable';
import { PopularDestinations } from '../components/PopularDestinations';
import { DashboardMultiChart } from '../components/DashboardMultiChart';
import { ActivityTimeline } from '../components/ActivityTimeline';

export function DashboardPage() {
  const { t } = useI18n();
  const [stats, setStats] = useState<DashboardStat[] | null>(null);
  const [articles, setArticles] = useState<PaginatedArticles | null>(null);
  const [destinations, setDestinations] = useState<PopularDestination[] | null>(null);
  const [activity, setActivity] = useState<ActivityLog[] | null>(null);
  const [chartData, setChartData] = useState<DashboardChartStats | null>(null);
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
      adminApi.chartStats(),
    ])
      .then(([s, d, a, c]) => {
        setStats(s.stats);
        setDestinations(d);
        setActivity(a);
        setChartData(c);
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

      <div className="dashboard-layout-cols">
        <div className="dashboard-main-col">
          <div className="card card-enter" style={{ '--stagger': 0 } as CSSProperties}>
            <div className="card-header">
              <h2>Thống kê Đa chiều</h2>
            </div>
            <DashboardMultiChart data={chartData} />
          </div>

          <div className="card card-enter" style={{ '--stagger': 1 } as CSSProperties}>
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
        </div>

        <div className="dashboard-side-col">
          <div className="card card-enter" style={{ '--stagger': 2 } as CSSProperties}>
            <div className="card-header">
              <h2>{t('dashboard.popularDestinations')}</h2>
              <button type="button" className="card-link" onClick={() => adminNavigate('destinations')}>
                {t('common.viewAll')}
              </button>
            </div>
            <PopularDestinations items={destinations} />
          </div>

          <div className="card card-enter" style={{ '--stagger': 3 } as CSSProperties}>
            <div className="card-header">
              <h2>{t('dashboard.recentActivity')}</h2>
            </div>
            <ActivityTimeline items={activity} />
            <button type="button" className="card-footer-link" onClick={() => adminNavigate('activity')}>
              {t('dashboard.allActivity')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
