import { useEffect, useState } from 'react';
import { adminApi, AdminDestination, GalleryImage, GalleryPayload } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { EditorModal } from '../components/EditorModal';
import { ImageUploadField } from '../components/ImageUploadField';
import { RowActionMenu } from '../components/RowActionMenu';
import { PenLineIcon, TrashIcon } from '../components/Icons';
import { useCrudMenuItems } from '../hooks/useArticleMenuItems';
import { useI18n } from '../i18n';

const emptyForm = (): GalleryPayload => ({
  title: '',
  imageUrl: '',
  destinationId: '',
  sortOrder: 1,
});

export function GalleryPage() {
  const { t } = useI18n();
  const crud = useCrudMenuItems();
  const [items, setItems] = useState<GalleryImage[]>([]);
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<GalleryPayload>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    Promise.all([adminApi.gallery(), adminApi.adminDestinations()])
      .then(([g, d]) => {
        setItems(g);
        setDestinations(d);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

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

  const openEdit = (g: GalleryImage) => {
    setEditingId(g.id);
    setForm({
      title: g.title,
      imageUrl: g.imageUrl,
      destinationId: g.destinationId ?? '',
      sortOrder: g.sortOrder,
    });
    setModalOpen(true);
  };

  const save = async () => {
    if (!form.title.trim() || !form.imageUrl.trim()) {
      setToast(t('gallery.validation'));
      return;
    }
    setSaving(true);
    try {
      const payload = { ...form, destinationId: form.destinationId || null };
      if (editingId) await adminApi.updateGallery(editingId, payload);
      else await adminApi.createGallery(payload);
      setToast(editingId ? t('gallery.savedUpdate') : t('gallery.savedCreate'));
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
      <Breadcrumb items={[{ label: t('gallery.title') }]} />
      <ContentToast message={toast} />
      <ContentPageHeader
        title={t('gallery.title')}
        description={t('gallery.description')}
        count={items.length}
        countLabel={t('gallery.countLabel')}
        actionLabel={t('gallery.create')}
        onAction={openCreate}
      />

      {loading ? (
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      ) : items.length === 0 ? (
        <div className="content-empty card"><p>{t('gallery.empty')}</p></div>
      ) : (
        <div className="gallery-grid">
          {items.map((g) => (
            <figure key={g.id} className="gallery-item asset-card">
              <div className="asset-card-menu">
                <RowActionMenu
                  open={openMenuId === g.id}
                  onToggle={() => setOpenMenuId((id) => (id === g.id ? null : g.id))}
                  onClose={() => setOpenMenuId(null)}
                  items={[
                    crud.edit(() => openEdit(g), <PenLineIcon size={16} />),
                    crud.delete(
                      g.title,
                      () => adminApi.deleteGallery(g.id).then(() => undefined),
                      (msg) => {
                        setToast(msg === t('actions.deleted', { name: g.title }) ? t('gallery.deleted') : msg);
                        load();
                      },
                      <TrashIcon size={16} />,
                    ),
                  ]}
                />
              </div>
              <img src={g.imageUrl} alt={g.title} />
              <figcaption>
                <strong>{g.title}</strong>
                {g.destinationName && <span>{g.destinationName}</span>}
              </figcaption>
            </figure>
          ))}
        </div>
      )}

      <EditorModal
        title={editingId ? t('gallery.modalEdit') : t('gallery.modalCreate')}
        open={modalOpen}
        saving={saving}
        onClose={() => setModalOpen(false)}
        onSave={save}
      >
        <label className="editor-field">
          <span className="field-label">{t('gallery.fieldTitle')}</span>
          <input className="editor-input" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        </label>
        <ImageUploadField value={form.imageUrl} onChange={(url) => setForm({ ...form, imageUrl: url })} />
        <label className="editor-field">
          <span className="field-label">{t('gallery.fieldDestination')}</span>
          <select className="editor-select" value={form.destinationId ?? ''} onChange={(e) => setForm({ ...form, destinationId: e.target.value })}>
            <option value="">{t('articles.noDestination')}</option>
            {destinations.map((d) => (
              <option key={d.id} value={d.id}>{d.name}</option>
            ))}
          </select>
        </label>
        <label className="editor-field">
          <span className="field-label">{t('gallery.fieldOrder')}</span>
          <input type="number" className="editor-input" value={form.sortOrder} onChange={(e) => setForm({ ...form, sortOrder: Number(e.target.value) })} />
        </label>
      </EditorModal>
    </div>
  );
}
