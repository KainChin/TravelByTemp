import { FormEvent, useEffect, useState } from 'react';
import { adminApi, AdminDestination, ArticleDetail } from '../api';
import { ArrowLeftIcon } from '../components/Icons';
import { Breadcrumb } from '../components/Breadcrumb';
import { ImageUploadField } from '../components/ImageUploadField';
import { RichTextEditor } from '../components/RichTextEditor';
import { usePermissions } from '../context/PermissionsContext';
import { useI18n } from '../i18n';
import { slugify } from '../lib/slugify';

export type ArticleEditorProps = {
  articleType: 'article' | 'news';
  listNav: 'articles' | 'news';
  listTitle: string;
  articleId?: string;
  onBack: () => void;
  onSaved: (message: string) => void;
  onDeleted?: (message: string) => void;
};

type FormState = {
  title: string;
  slug: string;
  summary: string;
  content: string;
  category: string;
  status: string;
  thumbnailUrl: string;
  destinationId: string;
};

const ARTICLE_CATEGORY_VALUES = ['destination', 'experience'] as const;
const NEWS_CATEGORY_VALUES = ['news'] as const;

const STATUS_OPTIONS = [
  { value: 'draft', label: 'Bản nháp' },
  { value: 'pending', label: 'Chờ duyệt' },
  { value: 'published', label: 'Đã xuất bản' },
];

function emptyForm(articleType: 'article' | 'news'): FormState {
  return {
    title: '',
    slug: '',
    summary: '',
    content: '',
    category: articleType === 'news' ? 'news' : 'destination',
    status: 'draft',
    thumbnailUrl: '',
    destinationId: '',
  };
}

function fromDetail(article: ArticleDetail): FormState {
  return {
    title: article.title,
    slug: article.slug,
    summary: article.summary ?? '',
    content: article.content,
    category: article.category,
    status: article.status,
    thumbnailUrl: article.thumbnailUrl ?? '',
    destinationId: article.destinationId ?? '',
  };
}

export function ArticleEditorPage({
  articleType,
  listNav,
  listTitle,
  articleId,
  onBack,
  onSaved,
  onDeleted,
}: ArticleEditorProps) {
  const { t } = useI18n();
  const { canPublish } = usePermissions();
  const isEdit = Boolean(articleId);
  const [form, setForm] = useState<FormState>(() => emptyForm(articleType));
  const [slugTouched, setSlugTouched] = useState(false);
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(isEdit);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    adminApi.adminDestinations().then(setDestinations).catch(() => {});
  }, []);

  useEffect(() => {
    if (!articleId) return;
    setLoading(true);
    adminApi
      .getArticle(articleId)
      .then((a) => {
        setForm(fromDetail(a));
        setSlugTouched(true);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [articleId]);

  const setField = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setForm((prev) => {
      const next = { ...prev, [key]: value };
      if (key === 'title' && !slugTouched) {
        next.slug = slugify(String(value));
      }
      return next;
    });
  };

  const validate = (): string | null => {
    if (!form.title.trim()) return t('articles.validationTitle');
    if (!form.slug.trim()) return t('articles.validationSlug');
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(form.slug)) {
      return t('articles.validationSlugFormat');
    }
    if (!form.content.replace(/<[^>]*>/g, '').trim()) return t('articles.validationContent');
    return null;
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const validationError = validate();
    if (validationError) {
      setError(validationError);
      return;
    }

    setSaving(true);
    setError('');
    const payload = {
      title: form.title.trim(),
      slug: form.slug.trim(),
      summary: form.summary.trim() || null,
      content: form.content.trim(),
      articleType,
      category: form.category,
      status: form.status,
      thumbnailUrl: form.thumbnailUrl.trim() || null,
      destinationId: form.destinationId || null,
    };

    try {
      if (isEdit && articleId) {
        await adminApi.updateArticle(articleId, payload);
        onSaved(t('articles.savedUpdate'));
      } else {
        await adminApi.createArticle(payload);
        onSaved(t('articles.savedCreate'));
      }
      onBack();
    } catch (err) {
      setError(err instanceof Error ? err.message : t('common.saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!articleId || !form.title.trim()) return;
    if (!window.confirm(t('common.confirmDeleteArticle', { name: form.title }))) return;
    setDeleting(true);
    setError('');
    try {
      await adminApi.deleteArticle(articleId);
      if (onDeleted) onDeleted(t('actions.deleted', { name: form.title }));
      else onSaved(t('actions.deleted', { name: form.title }));
      onBack();
    } catch (err) {
      setError(err instanceof Error ? err.message : t('common.deleteFailed'));
    } finally {
      setDeleting(false);
    }
  };

  const categories = articleType === 'news' ? NEWS_CATEGORY_VALUES : ARTICLE_CATEGORY_VALUES;
  const statusOptions = STATUS_OPTIONS.filter((o) => canPublish || o.value !== 'published');

  if (loading) {
    return (
      <div className="content-page">
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      </div>
    );
  }

  return (
    <div className="content-page">
      <Breadcrumb
        items={[
          { label: listTitle, to: `/admin/${listNav}` },
          { label: isEdit ? t('articles.editTitle') : t('articles.newTitle') },
        ]}
      />
      <div className="editor-page-head">
        <button type="button" className="btn-ghost" onClick={onBack}>
          <ArrowLeftIcon size={18} />
          {t('common.backToList')}
        </button>
        <h1>{isEdit ? t('articles.editTitle') : t('articles.newTitle')}</h1>
      </div>

      <form className="card editor-form" onSubmit={submit}>
        {error && (
          <div className="admin-error editor-error" role="alert">
            {error}
          </div>
        )}

        <div className="editor-grid">
          <div className="editor-main">
            <label className="editor-field">
              <span className="field-label">{t('articles.fieldTitle')}</span>
              <input
                className="editor-input"
                value={form.title}
                onChange={(e) => setField('title', e.target.value)}
                placeholder={t('articles.fieldTitlePlaceholder')}
              />
            </label>

            <label className="editor-field">
              <span className="field-label">{t('articles.fieldSlug')}</span>
              <input
                className="editor-input editor-input-mono"
                value={form.slug}
                onChange={(e) => {
                  setSlugTouched(true);
                  setField('slug', slugify(e.target.value));
                }}
                placeholder={t('articles.fieldSlugPlaceholder')}
              />
            </label>

            <label className="editor-field">
              <span className="field-label">{t('articles.fieldSummary')}</span>
              <textarea
                className="editor-textarea editor-textarea-sm"
                rows={3}
                value={form.summary}
                onChange={(e) => setField('summary', e.target.value)}
                placeholder={t('articles.fieldSummaryPlaceholder')}
              />
            </label>

            <div className="editor-field">
              <span className="field-label">{t('articles.fieldContent')}</span>
              <RichTextEditor
                value={form.content}
                onChange={(html) => setField('content', html)}
                placeholder={t('articles.fieldContentPlaceholder')}
              />
            </div>
          </div>

          <aside className="editor-sidebar">
            <div className="editor-panel">
              <h3>{t('articles.publishPanel')}</h3>
              <label className="editor-field">
                <span className="field-label">{t('table.status')}</span>
                <select
                  className="editor-select"
                  value={form.status}
                  onChange={(e) => setField('status', e.target.value)}
                >
                  {statusOptions.map((o) => (
                    <option key={o.value} value={o.value}>
                      {t(`status.${o.value}` as 'status.draft')}
                    </option>
                  ))}
                </select>
              </label>

              <label className="editor-field">
                <span className="field-label">{t('table.category')}</span>
                <select
                  className="editor-select"
                  value={form.category}
                  onChange={(e) => setField('category', e.target.value)}
                >
                  {categories.map((value) => (
                    <option key={value} value={value}>
                      {t(`category.${value}`)}
                    </option>
                  ))}
                </select>
              </label>
            </div>

            <div className="editor-panel">
              <h3>{t('articles.mediaPanel')}</h3>
              <ImageUploadField
                label={t('articles.thumbnail')}
                value={form.thumbnailUrl}
                onChange={(url) => setField('thumbnailUrl', url)}
              />
              <label className="editor-field">
                <span className="field-label">{t('articles.relatedDestination')}</span>
                <select
                  className="editor-select"
                  value={form.destinationId}
                  onChange={(e) => setField('destinationId', e.target.value)}
                >
                  <option value="">{t('articles.noDestination')}</option>
                  {destinations.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name} ({d.province})
                    </option>
                  ))}
                </select>
              </label>
            </div>
          </aside>
        </div>

        <div className="editor-actions editor-actions-split">
          {isEdit && (
            <button
              type="button"
              className="btn-danger-outline"
              disabled={saving || deleting}
              onClick={handleDelete}
            >
              {deleting ? t('common.deleting') : t('actions.deleteArticle')}
            </button>
          )}
          <div className="editor-actions-right">
            <button type="button" className="btn-secondary" onClick={onBack} disabled={saving || deleting}>
              {t('common.cancel')}
            </button>
            <button type="submit" className="btn-primary" disabled={saving || deleting}>
              {saving ? t('common.saving') : isEdit ? t('common.update') : t('articles.createButton')}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
