import { FormEvent, useEffect, useState } from 'react';
import { adminApi, DestinationPayload } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ArrowLeftIcon } from '../components/Icons';
import { ImageUploadField } from '../components/ImageUploadField';
import { slugify } from '../lib/slugify';
import { useI18n } from '../i18n';

type Props = {
  destinationId?: string;
  onBack: () => void;
  onSaved: (message: string) => void;
  onDeleted?: (message: string) => void;
};

const REGION_KEYS = ['North', 'Central', 'South', 'West'] as const;

function emptyForm(): DestinationPayload {
  return {
    name: '',
    slug: '',
    description: '',
    province: '',
    region: 'Central',
    latitude: 16,
    longitude: 108,
    category: 'Beach',
    estimatedCost: 0,
    imageUrl: '',
  };
}

export function DestinationEditorPage({ destinationId, onBack, onSaved, onDeleted }: Props) {
  const { t } = useI18n();
  const isEdit = Boolean(destinationId);
  const [form, setForm] = useState<DestinationPayload>(emptyForm);
  const [slugTouched, setSlugTouched] = useState(false);
  const [loading, setLoading] = useState(isEdit);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!destinationId) return;
    setLoading(true);
    adminApi
      .getDestination(destinationId)
      .then((d) => {
        setForm({
          name: d.name,
          slug: d.slug,
          description: d.description,
          province: d.province,
          region: d.region,
          latitude: Number(d.latitude),
          longitude: Number(d.longitude),
          category: d.category,
          estimatedCost: Number(d.estimatedCost),
          imageUrl: d.imageUrl ?? '',
        });
        setSlugTouched(true);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [destinationId]);

  const setField = <K extends keyof DestinationPayload>(key: K, value: DestinationPayload[K]) => {
    setForm((prev) => {
      const next = { ...prev, [key]: value };
      if (key === 'name' && !slugTouched) next.slug = slugify(String(value));
      return next;
    });
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.slug.trim()) {
      setError(t('destinations.validationRequired'));
      return;
    }
    setSaving(true);
    setError('');
    try {
      const payload = { ...form, imageUrl: form.imageUrl || null };
      if (isEdit && destinationId) {
        await adminApi.updateDestination(destinationId, payload);
        onSaved(t('destinations.savedUpdate'));
      } else {
        await adminApi.createDestination(payload);
        onSaved(t('destinations.savedCreate'));
      }
      onBack();
    } catch (err) {
      setError(err instanceof Error ? err.message : t('common.saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!destinationId || !form.name.trim()) return;
    if (!window.confirm(t('common.confirmDeleteDestinationEditor', { name: form.name }))) return;
    setDeleting(true);
    setError('');
    try {
      await adminApi.deleteDestination(destinationId);
      const msg = t('actions.deleted', { name: form.name });
      if (onDeleted) onDeleted(msg);
      else onSaved(msg);
      onBack();
    } catch (err) {
      setError(err instanceof Error ? err.message : t('common.deleteFailed'));
    } finally {
      setDeleting(false);
    }
  };

  if (loading) {
    return <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>;
  }

  const listTitle = t('destinations.title');
  const pageTitle = isEdit ? t('destinations.editTitle') : t('destinations.newTitle');

  return (
    <div className="content-page">
      <Breadcrumb
        items={[
          { label: listTitle, to: '/admin/destinations' },
          { label: pageTitle },
        ]}
      />
      <div className="editor-page-head">
        <button type="button" className="btn-ghost" onClick={onBack}>
          <ArrowLeftIcon size={18} />
          {t('common.backToList')}
        </button>
        <h1>{pageTitle}</h1>
      </div>

      <form className="card editor-form" onSubmit={submit}>
        {error && <div className="admin-error editor-error">{error}</div>}

        <div className="editor-grid">
          <div className="editor-main">
            <label className="editor-field">
              <span className="field-label">{t('destinations.fieldName')}</span>
              <input className="editor-input" value={form.name} onChange={(e) => setField('name', e.target.value)} />
            </label>
            <label className="editor-field">
              <span className="field-label">{t('destinations.fieldSlug')}</span>
              <input
                className="editor-input editor-input-mono"
                value={form.slug}
                onChange={(e) => {
                  setSlugTouched(true);
                  setField('slug', slugify(e.target.value));
                }}
              />
            </label>
            <label className="editor-field">
              <span className="field-label">{t('destinations.fieldDescription')}</span>
              <textarea className="editor-textarea" rows={5} value={form.description} onChange={(e) => setField('description', e.target.value)} />
            </label>
            <div className="editor-field-row">
              <label className="editor-field">
                <span className="field-label">{t('destinations.fieldLat')}</span>
                <input type="number" step="any" className="editor-input" value={form.latitude} onChange={(e) => setField('latitude', Number(e.target.value))} />
              </label>
              <label className="editor-field">
                <span className="field-label">{t('destinations.fieldLng')}</span>
                <input type="number" step="any" className="editor-input" value={form.longitude} onChange={(e) => setField('longitude', Number(e.target.value))} />
              </label>
            </div>
          </div>

          <aside className="editor-sidebar">
            <div className="editor-panel">
              <h3>{t('destinations.classify')}</h3>
              <label className="editor-field">
                <span className="field-label">{t('destinations.province')}</span>
                <input className="editor-input" value={form.province} onChange={(e) => setField('province', e.target.value)} />
              </label>
              <label className="editor-field">
                <span className="field-label">{t('destinations.region')}</span>
                <select className="editor-select" value={form.region} onChange={(e) => setField('region', e.target.value)}>
                  {REGION_KEYS.map((value) => (
                    <option key={value} value={value}>{t(`region.${value}`)}</option>
                  ))}
                </select>
              </label>
              <label className="editor-field">
                <span className="field-label">{t('destinations.type')}</span>
                <input className="editor-input" value={form.category} onChange={(e) => setField('category', e.target.value)} placeholder={t('destinations.typePlaceholder')} />
              </label>
              <label className="editor-field">
                <span className="field-label">{t('destinations.cost')}</span>
                <input type="number" className="editor-input" value={form.estimatedCost} onChange={(e) => setField('estimatedCost', Number(e.target.value))} />
              </label>
            </div>
            <div className="editor-panel">
              <h3>{t('destinations.image')}</h3>
              <ImageUploadField value={form.imageUrl ?? ''} onChange={(url) => setField('imageUrl', url)} />
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
              {deleting ? t('common.deleting') : t('actions.deleteDestination')}
            </button>
          )}
          <div className="editor-actions-right">
            <button type="button" className="btn-secondary" onClick={onBack} disabled={saving || deleting}>
              {t('common.cancel')}
            </button>
            <button type="submit" className="btn-primary" disabled={saving || deleting}>
              {saving ? t('common.saving') : isEdit ? t('common.update') : t('common.create')}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
