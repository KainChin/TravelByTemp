import { useCallback, useEffect, useState } from 'react';
import { adminApi, adminNavigate, ArticleDetail, ArticleListItem, PaginatedArticles } from '../api';
import { AuthorCell, CategoryTag, StatusTag } from '../components/ContentTags';
import { Breadcrumb } from '../components/Breadcrumb';
import { useArticleMenuItems } from '../hooks/useArticleMenuItems';
import { useI18n } from '../i18n';
import {
  ChevronLeftIcon,
  ChevronRightIcon,
} from '../components/Icons';
import { RowActionMenu } from '../components/RowActionMenu';

type Props = {
  title: string;
  description: string;
  articleType: 'article' | 'news';
  listNav: 'articles' | 'news';
};

const STATUS_FILTER_KEYS = ['', 'published', 'pending', 'draft'] as const;

function ArticleDetailModal({
  article,
  onClose,
}: {
  article: ArticleDetail;
  onClose: () => void;
}) {
  const { t, formatNumber } = useI18n();
  return (
    <div className="admin-modal-backdrop" onClick={onClose} role="presentation">
      <div
        className="admin-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="article-detail-title"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="admin-modal-header">
          <div>
            <p className="admin-modal-eyebrow">{t('articles.detailEyebrow')}</p>
            <h2 id="article-detail-title">{article.title}</h2>
          </div>
          <button type="button" className="icon-btn" onClick={onClose} aria-label={t('common.close')}>
            ×
          </button>
        </div>
        <div className="admin-modal-body">
          {article.thumbnailUrl && (
            <img src={article.thumbnailUrl} alt="" className="admin-modal-thumb" />
          )}
          <dl className="detail-meta">
            <div>
              <dt>{t('articles.slug')}</dt>
              <dd>{article.slug}</dd>
            </div>
            <div>
              <dt>{t('table.author')}</dt>
              <dd>{article.author.fullName}</dd>
            </div>
            <div>
              <dt>{t('table.status')}</dt>
              <dd>{article.status}</dd>
            </div>
            <div>
              <dt>{t('articles.views')}</dt>
              <dd>{formatNumber(article.viewCount)}</dd>
            </div>
          </dl>
          {article.summary && <p className="detail-summary">{article.summary}</p>}
        </div>
      </div>
    </div>
  );
}

export function ArticlesPage({ title, description, articleType, listNav }: Props) {
  const { t, formatNumber } = useI18n();
  const buildMenuItems = useArticleMenuItems();
  const [data, setData] = useState<PaginatedArticles | null>(null);
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);
  const [toast, setToast] = useState('');
  const [detail, setDetail] = useState<ArticleDetail | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const load = useCallback(() => {
    setLoading(true);
    adminApi
      .articles({ page, pageSize: 10, articleType, status: status || undefined })
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [page, status, articleType]);

  useEffect(() => {
    const flash = sessionStorage.getItem('admin_flash');
    if (flash) {
      setToast(flash);
      sessionStorage.removeItem('admin_flash');
    }
  }, []);

  useEffect(() => {
    load();
  }, [load, refreshKey]);

  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(t);
  }, [toast]);

  const notify = (message: string) => setToast(message);

  const buildMenuItemsForRow = (row: ArticleListItem) =>
    buildMenuItems(row, {
      listNav,
      onNotify: (msg) => {
        notify(msg);
        setRefreshKey((k) => k + 1);
      },
      includeView: true,
      onViewDetail: (r) => {
        adminApi.getArticle(r.id).then(setDetail).catch((e) => notify(e.message));
      },
    });

  if (error) return <div className="admin-error">{error}</div>;

  const start = data ? (data.page - 1) * data.pageSize + 1 : 0;
  const end = data ? Math.min(data.page * data.pageSize, data.totalCount) : 0;

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: title }]} />
      {toast && (
        <div className="content-toast" role="status">
          {toast}
        </div>
      )}

      <div className="content-page-head">
        <div className="page-header content-page-intro">
          <h1>{title}</h1>
          <p>{description}</p>
        </div>
        <div className="content-page-actions">
          {data && (
            <span className="count-badge">{formatNumber(data.totalCount)} {t('common.items')}</span>
          )}
          <button
            type="button"
            className="btn-primary"
            onClick={() => adminNavigate(`${listNav}/new`)}
          >
            {t('articles.create')}
          </button>
        </div>
      </div>

      <div className="card content-card">
        <div className="content-card-bar">
          <div className="filter-tabs" role="tablist" aria-label={t('filter.status')}>
            {STATUS_FILTER_KEYS.map((value) => (
              <button
                key={value || 'all'}
                type="button"
                role="tab"
                aria-selected={status === value}
                className={`filter-tab${status === value ? ' active' : ''}`}
                onClick={() => {
                  setPage(1);
                  setStatus(value);
                }}
              >
                {value ? t(`status.${value}`) : t('filter.all')}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
        ) : !data?.items.length ? (
          <div className="content-empty">
            <p>{t('articles.empty')}</p>
          </div>
        ) : (
          <>
            <div className="table-wrap">
              <table className="admin-table content-table">
                <thead>
                  <tr>
                    <th>{t('table.title')}</th>
                    <th>{t('table.category')}</th>
                    <th>{t('table.author')}</th>
                    <th>{t('table.status')}</th>
                    <th className="col-actions" aria-label={t('common.actions')} />
                  </tr>
                </thead>
                <tbody>
                  {data.items.map((row) => (
                    <tr key={row.id}>
                      <td>
                        <div className="article-title-cell">
                          {row.thumbnailUrl ? (
                            <img src={row.thumbnailUrl} alt="" className="article-thumb" />
                          ) : (
                            <span className="article-thumb article-thumb-fallback" aria-hidden="true" />
                          )}
                          <span className="article-title-text">{row.title}</span>
                        </div>
                      </td>
                      <td>
                        <CategoryTag category={row.category} />
                      </td>
                      <td>
                        <AuthorCell name={row.author.fullName} />
                      </td>
                      <td>
                        <StatusTag status={row.status} />
                      </td>
                      <td className="col-actions">
                        <RowActionMenu
                          open={openMenuId === row.id}
                          onToggle={() =>
                            setOpenMenuId((id) => (id === row.id ? null : row.id))
                          }
                          onClose={() => setOpenMenuId(null)}
                          items={buildMenuItemsForRow(row)}
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {data.totalCount > 0 && (
              <div className="table-footer content-table-footer">
                <span>
                  {t('common.showingRange', {
                    start,
                    end,
                    total: formatNumber(data.totalCount),
                  })}
                </span>
                <div className="pagination">
                  <button
                    type="button"
                    className="icon-btn"
                    disabled={page <= 1}
                    onClick={() => setPage(page - 1)}
                    aria-label={t('common.prevPage')}
                  >
                    <ChevronLeftIcon size={16} />
                  </button>
                  <span className="pagination-current">
                    {t('common.pageOf', { page, total: data.totalPages })}
                  </span>
                  <button
                    type="button"
                    className="icon-btn"
                    disabled={page >= data.totalPages}
                    onClick={() => setPage(page + 1)}
                    aria-label={t('common.nextPage')}
                  >
                    <ChevronRightIcon size={16} />
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {detail && <ArticleDetailModal article={detail} onClose={() => setDetail(null)} />}
    </div>
  );
}
