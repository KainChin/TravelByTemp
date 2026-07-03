import { useEffect, useState } from 'react';
import { adminApi, FeaturedContent, FeaturedPayload } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { EditorModal } from '../components/EditorModal';
import { ImageUploadField } from '../components/ImageUploadField';
import { RowActionMenu } from '../components/RowActionMenu';
import { PenLineIcon, TrashIcon } from '../components/Icons';
import { useCrudMenuItems } from '../hooks/useArticleMenuItems';
import { useI18n } from '../i18n';

const CONTENT_TYPES = ['article', 'destination', 'news'] as const;

const emptyForm = (): FeaturedPayload => ({
  title: '',
  subtitle: '',
  imageUrl: '',
  linkUrl: '',
  contentType: 'article',
  isActive: true,
  sortOrder: 1,
});

export function FeaturedPage() {
  const { t } = useI18n();
  const crud = useCrudMenuItems();
  const [items, setItems] = useState<FeaturedContent[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FeaturedPayload>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    adminApi.featured().then(setItems).catch((e) => setError(e.message)).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const typeLabel = (type: string) => {
    const key = `featured.type${type.charAt(0).toUpperCase()}${type.slice(1)}` as
      | 'featured.typeArticle'
      | 'featured.typeDestination'
      | 'featured.typeNews';
    const label = t(key);
    return label === key ? type : label;
  };

  const openCreate = () => {
    setEditingId(null);
    setForm(emptyForm());
    setModalOpen(true);
  };

  const openEdit = (f: FeaturedContent) => {
    setEditingId(f.id);
    setForm({
      title: f.title,
      subtitle: f.subtitle ?? '',
      imageUrl: f.imageUrl ?? '',
      linkUrl: f.linkUrl ?? '',
      contentType: f.contentType,
      isActive: f.isActive,
      sortOrder: f.sortOrder,
    });
    setModalOpen(true);
  };

  const save = async () => {
    if (!form.title.trim()) {
      setToast(t('featured.validation'));
      return;
    }
    setSaving(true);
    try {
      const payload = {
        ...form,
        subtitle: form.subtitle || null,
        imageUrl: form.imageUrl || null,
        linkUrl: form.linkUrl || null,
      };
      if (editingId) await adminApi.updateFeatured(editingId, payload);
      else await adminApi.createFeatured(payload);
      setToast(editingId ? t('featured.savedUpdate') : t('featured.savedCreate'));
      setModalOpen(false);
      load();
    } catch (e) {
      setToast(e instanceof Error ? e.message : t('common.saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  if (error) return <div className="admin-error">{error}</div>;

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('featured.title') }]} />
      <ContentToast message={toast} />
      <ContentPageHeader
        title={t('featured.title')}
        description={t('featured.description')}
        count={items.length}
        countLabel={t('featured.countLabel')}
        actionLabel={t('featured.create')}
        onAction={openCreate}
      />

      {loading ? (
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      ) : items.length === 0 ? (
        <div className="content-empty card"><p>{t('featured.empty')}</p></div>
      ) : (
        <div className="featured-list">
          {items.map((f) => (
            <article key={f.id} className="featured-row asset-card">
              <div className="asset-card-menu asset-card-menu-row">
                <RowActionMenu
                  open={openMenuId === f.id}
                  onToggle={() => setOpenMenuId((id) => (id === f.id ? null : f.id))}
                  onClose={() => setOpenMenuId(null)}
                  items={[
                    crud.edit(() => openEdit(f), <PenLineIcon size={16} />),
                    crud.delete(
                      f.title,
                      () => adminApi.deleteFeatured(f.id).then(() => undefined),
                      (msg) => {
                        setToast(msg === t('actions.deleted', { name: f.title }) ? t('featured.deleted') : msg);
                        load();
                      },
                      <TrashIcon size={16} />,
                    ),
                  ]}
                />
              </div>
              {f.imageUrl ? (
                <img src={f.imageUrl} alt="" className="featured-thumb" />
              ) : (
                <div className="featured-thumb featured-placeholder" />
              )}
              <div className="featured-body">
                <h3>{f.title}</h3>
                {f.subtitle && <p>{f.subtitle}</p>}
                <div className="featured-meta">
                  <span className={`tag tag-status tag-${f.isActive ? 'published' : 'draft'}`}>
                    {f.isActive ? t('common.active') : t('common.inactive')}
                  </span>
                  <span>{typeLabel(f.contentType)}</span>
                  <span>#{f.sortOrder}</span>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}

      <EditorModal
        title={editingId ? t('featured.modalEdit') : t('featured.modalCreate')}
        open={modalOpen}
        saving={saving}
        onClose={() => setModalOpen(false)}
        onSave={save}
      >
        <label className="editor-field">
          <span className="field-label">{t('featured.fieldTitle')}</span>
          <input className="editor-input" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        </label>
        <label className="editor-field">
          <span className="field-label">{t('featured.fieldSubtitle')}</span>
          <input className="editor-input" value={form.subtitle ?? ''} onChange={(e) => setForm({ ...form, subtitle: e.target.value })} />
        </label>
        <ImageUploadField value={form.imageUrl ?? ''} onChange={(url) => setForm({ ...form, imageUrl: url })} />
        <label className="editor-field">
          <span className="field-label">{t('featured.fieldLink')}</span>
          <input className="editor-input" value={form.linkUrl ?? ''} onChange={(e) => setForm({ ...form, linkUrl: e.target.value })} />
        </label>
        <label className="editor-field">
          <span className="field-label">{t('featured.fieldType')}</span>
          <select className="editor-select" value={form.contentType} onChange={(e) => setForm({ ...form, contentType: e.target.value })}>
            {CONTENT_TYPES.map((type) => (
              <option key={type} value={type}>{typeLabel(type)}</option>
            ))}
          </select>
        </label>
        <label className="editor-field">
          <span className="field-label">{t('featured.fieldOrder')}</span>
          <input type="number" className="editor-input" value={form.sortOrder} onChange={(e) => setForm({ ...form, sortOrder: Number(e.target.value) })} />
        </label>
        <label className="editor-field editor-checkbox">
          <input type="checkbox" checked={form.isActive} onChange={(e) => setForm({ ...form, isActive: e.target.checked })} />
          <span>{t('featured.fieldActive')}</span>
        </label>
      </EditorModal>
    </div>
  );
}
