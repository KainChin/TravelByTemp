import { useCallback, useEffect, useState } from 'react';
import { adminApi, PaginatedActivityLogs } from '../api';
import { ActivityTimeline } from '../components/ActivityTimeline';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader } from '../components/ContentPageHeader';
import { useI18n } from '../i18n';

export function ActivityPage() {
  const { t } = useI18n();
  const [data, setData] = useState<PaginatedActivityLogs | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(() => {
    setLoading(true);
    adminApi
      .activityLogs({ page, pageSize: 20 })
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('activity.title') }]} />
      <ContentPageHeader title={t('activity.title')} description={t('activity.description')} />

      {error && <p className="content-error">{error}</p>}

      <div className="content-card activity-page-card">
        <ActivityTimeline items={data?.items ?? null} loading={loading} />

        {data && data.totalPages > 1 && (
          <div className="content-pagination">
            <button type="button" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              {t('common.prevPage')}
            </button>
            <span>{t('common.pageOf', { page, total: data.totalPages })}</span>
            <button
              type="button"
              disabled={page >= data.totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              {t('common.nextPage')}
            </button>
          </div>
        )}

        {data && data.totalCount > 0 && (
          <p className="activity-count">
            {t('common.showingRange', {
              start: (data.page - 1) * data.pageSize + 1,
              end: Math.min(data.page * data.pageSize, data.totalCount),
              total: data.totalCount,
            })}
          </p>
        )}
      </div>
    </div>
  );
}
