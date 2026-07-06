import { useEffect, useState } from 'react';
import { adminApi, Banner, BannerPayload } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { EditorModal } from '../components/EditorModal';
import { ImageUploadField } from '../components/ImageUploadField';
import { RowActionMenu } from '../components/RowActionMenu';
import { PenLineIcon, TrashIcon } from '../components/Icons';
import { useCrudMenuItems } from '../hooks/useArticleMenuItems';
import { useI18n } from '../i18n';

const emptyForm = (): BannerPayload => ({
  title: '',
  imageUrl: '',
  linkUrl: '',
  sortOrder: 1,
  isActive: true,
  region: 'North',
});

export function BannersPage() {
  const { t } = useI18n();
  const crud = useCrudMenuItems();
  const [items, setItems] = useState<Banner[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<BannerPayload>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    adminApi.banners().then(setItems).catch((e) => setError(e.message)).finally(() => setLoading(false));
  };

  useEffect(() => {
    const flash = sessionStorage.getItem('admin_flash');
    if (flash) {
      setToast(flash);
      sessionStorage.removeItem('admin_flash');
    }
    load();
  }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const openCreate = () => {
    setEditingId(null);
    setForm(emptyForm());
    setModalOpen(true);
  };

  const openEdit = (b: Banner) => {
    setEditingId(b.id);
    setForm({
      title: b.title,
      imageUrl: b.imageUrl,
      linkUrl: b.linkUrl ?? '',
      sortOrder: b.sortOrder,
      isActive: b.isActive,
      region: b.region || 'North',
    });
    setModalOpen(true);
  };

  const save = async () => {
    if (!form.title.trim() || !form.imageUrl.trim()) {
      setToast(t('banners.validation'));
      return;
    }
    setSaving(true);
    try {
      const payload = { ...form, linkUrl: form.linkUrl || null };
      if (editingId) {
        await adminApi.updateBanner(editingId, payload);
        setToast(t('banners.savedUpdate'));
      } else {
        await adminApi.createBanner(payload);
        setToast(t('banners.savedCreate'));
      }
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
      <Breadcrumb items={[{ label: t('banners.title') }]} />
      <ContentToast message={toast} />
      <ContentPageHeader
        title={t('banners.title')}
        description={t('banners.description')}
        count={items.length}
        countLabel={t('banners.countLabel')}
        actionLabel={t('banners.create')}
        onAction={openCreate}
      />

      {loading ? (
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      ) : items.length === 0 ? (
        <div className="content-empty card"><p>{t('banners.empty')}</p></div>
      ) : (
        <div className="media-grid">
          {items.map((b) => (
            <article key={b.id} className="media-card asset-card">
              <img src={b.imageUrl} alt="" className="media-card-img" />
              <div className="media-card-body">
                <h3>{b.title}</h3>
                <div className="media-card-meta">
                  <span className={`tag tag-status tag-${b.isActive ? 'published' : 'draft'}`}>
                    {b.isActive ? t('common.active') : t('common.inactive')}
                  </span>
                  <span className="tag" style={{ background: 'var(--bg-elevated)', border: '1px solid var(--border)' }}>
                    {b.region}
                  </span>
                  <span>#{b.sortOrder}</span>
                </div>
                <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                  <button
                    type="button"
                    className="btn-ghost btn-sm"
                    onClick={() => openEdit(b)}
                  >
                    <PenLineIcon size={14} style={{ marginRight: 4 }} />
                    {t('common.edit')}
                  </button>
                  <button
                    type="button"
                    className="btn-ghost btn-sm"
                    style={{ color: 'var(--color-danger)' }}
                    onClick={async () => {
                      if (!window.confirm(t('common.confirmDelete', { name: b.title }))) return;
                      try {
                        await adminApi.deleteBanner(b.id);
                        setToast(t('banners.deleted'));
                        load();
                      } catch (e) {
                        setToast(e instanceof Error ? e.message : t('common.actionFailed'));
                      }
                    }}
                  >
                    <TrashIcon size={14} style={{ marginRight: 4 }} />
                    {t('common.delete')}
                  </button>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}

      <EditorModal
        title={editingId ? t('banners.modalEdit') : t('banners.modalCreate')}
        open={modalOpen}
        saving={saving}
        onClose={() => setModalOpen(false)}
        onSave={save}
      >
        <label className="editor-field">
          <span className="field-label">{t('banners.fieldTitle')}</span>
          <input className="editor-input" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        </label>
        <ImageUploadField value={form.imageUrl} onChange={(url) => setForm({ ...form, imageUrl: url })} />
        <label className="editor-field">
          <span className="field-label">{t('banners.fieldLink')}</span>
          <input className="editor-input" value={form.linkUrl ?? ''} onChange={(e) => setForm({ ...form, linkUrl: e.target.value })} />
        </label>
        <label className="editor-field">
          <span className="field-label">{t('banners.fieldOrder')}</span>
          <input type="number" className="editor-input" value={form.sortOrder} onChange={(e) => setForm({ ...form, sortOrder: Number(e.target.value) })} />
        </label>
        <label className="editor-field">
          <span className="field-label">Miền (Region)</span>
          <select className="editor-input" value={form.region} onChange={(e) => setForm({ ...form, region: e.target.value })}>
            <option value="North">Miền Bắc (North)</option>
            <option value="Central">Miền Trung (Central)</option>
            <option value="South">Miền Nam (South)</option>
            <option value="West">Miền Tây (West)</option>
          </select>
        </label>
        <label className="editor-field editor-checkbox">
          <input type="checkbox" checked={form.isActive} onChange={(e) => setForm({ ...form, isActive: e.target.checked })} />
          <span>{t('banners.fieldActive')}</span>
        </label>
      </EditorModal>
    </div>
  );
}
