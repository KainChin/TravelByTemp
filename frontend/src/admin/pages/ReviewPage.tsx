import { useCallback, useEffect, useState } from 'react';
import { adminApi, adminNavigate, ArticleListItem, PaginatedArticles } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { AuthorCell, CategoryTag, StatusTag } from '../components/ContentTags';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { usePermissions } from '../context/PermissionsContext';
import { useI18n } from '../i18n';
import { CheckCircleIcon, PenLineIcon } from '../components/Icons';

export function ReviewPage() {
  const { t } = useI18n();
  const { canPublish } = usePermissions();
  const [data, setData] = useState<PaginatedArticles | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [publishing, setPublishing] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    adminApi
      .articles({ page, pageSize: 15, status: 'pending' })
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleAll = () => {
    if (!data?.items.length) return;
    if (selected.size === data.items.length) {
      setSelected(new Set());
    } else {
      setSelected(new Set(data.items.map((a) => a.id)));
    }
  };

  const bulkPublish = async () => {
    if (!selected.size) return;
    setPublishing(true);
    try {
      const res = await adminApi.bulkPublishArticles([...selected]);
      setToast(t('review.bulkPublished', { count: res.published }));
      setSelected(new Set());
      load();
    } catch (e) {
      setToast(e instanceof Error ? e.message : t('common.actionFailed'));
    } finally {
      setPublishing(false);
    }
  };

  const rows = data?.items ?? [];

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('review.title') }]} />
      <ContentPageHeader title={t('review.title')} description={t('review.description')}>
        {canPublish && (
          <button
            type="button"
            className="btn-primary"
            disabled={!selected.size || publishing}
            onClick={bulkPublish}
          >
            <CheckCircleIcon size={16} />
            {publishing ? t('review.publishing') : t('review.bulkPublish', { count: selected.size })}
          </button>
        )}
      </ContentPageHeader>
      <ContentToast message={toast} />

      {error && <p className="content-error">{error}</p>}

      <div className="content-card">
        {loading ? (
          <p className="content-muted">{t('common.loading')}…</p>
        ) : rows.length === 0 ? (
          <p className="content-muted">{t('review.empty')}</p>
        ) : (
          <table className="content-table">
            <thead>
              <tr>
                {canPublish && (
                  <th scope="col">
                    <input
                      type="checkbox"
                      aria-label={t('review.selectAll')}
                      checked={selected.size === rows.length && rows.length > 0}
                      onChange={toggleAll}
                    />
                  </th>
                )}
                <th scope="col">{t('table.title')}</th>
                <th scope="col">{t('table.category')}</th>
                <th scope="col">{t('table.author')}</th>
                <th scope="col">{t('table.status')}</th>
                <th scope="col">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row: ArticleListItem) => (
                <tr key={row.id}>
                  {canPublish && (
                    <td>
                      <input
                        type="checkbox"
                        checked={selected.has(row.id)}
                        onChange={() => toggle(row.id)}
                        aria-label={row.title}
                      />
                    </td>
                  )}
                  <td>{row.title}</td>
                  <td>
                    <CategoryTag category={row.category} />
                  </td>
                  <td>
                    <AuthorCell name={row.author.fullName} />
                  </td>
                  <td>
                    <StatusTag status={row.status} />
                  </td>
                  <td>
                    <button
                      type="button"
                      className="btn-ghost btn-sm"
                      onClick={() =>
                        adminNavigate(row.category === 'news' ? `news/edit/${row.id}` : `articles/edit/${row.id}`)
                      }
                    >
                      <PenLineIcon size={14} />
                      {t('actions.edit')}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {data && data.totalPages > 1 && (
        <div className="content-pagination">
          <button type="button" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
            {t('common.prevPage')}
          </button>
          <span>{t('common.pageOf', { page, total: data.totalPages })}</span>
          <button type="button" disabled={page >= data.totalPages} onClick={() => setPage((p) => p + 1)}>
            {t('common.nextPage')}
          </button>
        </div>
      )}
    </div>
  );
}
