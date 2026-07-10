import { CSSProperties } from 'react';
import { useI18n } from '../i18n';
import { ArticleListItem, PaginatedArticles } from '../api';
import { CategoryTag, StatusTag } from './ContentTags';
import { RowActionMenu } from './RowActionMenu';
import { useArticleMenuItems } from '../hooks/useArticleMenuItems';
import { ChevronLeftIcon, ChevronRightIcon } from './Icons';

export function RecentArticlesTable({
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
