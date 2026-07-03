import { useEffect, useState } from 'react';
import { adminApi, PendingComment } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { useI18n } from '../i18n';
import { CheckCircleIcon, XIcon } from '../components/Icons';

export function CommentsPage() {
  const { t, formatTimeAgo } = useI18n();
  const [items, setItems] = useState<PendingComment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    adminApi
      .pendingComments()
      .then(setItems)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const moderate = async (id: string, action: 'approve' | 'reject') => {
    setBusyId(id);
    try {
      if (action === 'approve') await adminApi.approveComment(id);
      else await adminApi.rejectComment(id);
      setToast(action === 'approve' ? t('comments.approved') : t('comments.rejected'));
      setItems((prev) => prev.filter((c) => c.id !== id));
    } catch (e) {
      setToast(e instanceof Error ? e.message : t('common.actionFailed'));
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('comments.title') }]} />
      <ContentPageHeader title={t('comments.title')} description={t('comments.description')} />
      <ContentToast message={toast} />

      {error && <p className="content-error">{error}</p>}

      <div className="content-card">
        {loading ? (
          <p className="content-muted">{t('common.loading')}…</p>
        ) : items.length === 0 ? (
          <p className="content-muted">{t('comments.empty')}</p>
        ) : (
          <div className="comment-review-list">
            {items.map((c) => (
              <article key={c.id} className="comment-review-card">
                <header>
                  <strong>{c.destinationName}</strong>
                  <span className="comment-meta">
                    {c.fullName || c.username} · {formatTimeAgo(c.createdAt)} · ★ {c.rating}
                  </span>
                </header>
                {c.content && <p>{c.content}</p>}
                <div className="comment-review-actions">
                  <button
                    type="button"
                    className="btn-primary btn-sm"
                    disabled={busyId === c.id}
                    onClick={() => moderate(c.id, 'approve')}
                  >
                    <CheckCircleIcon size={14} />
                    {t('comments.approve')}
                  </button>
                  <button
                    type="button"
                    className="btn-ghost btn-sm danger"
                    disabled={busyId === c.id}
                    onClick={() => moderate(c.id, 'reject')}
                  >
                    <XIcon size={14} />
                    {t('comments.reject')}
                  </button>
                </div>
              </article>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
