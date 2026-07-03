import { useEffect, useState } from 'react';
import { adminApi, adminNavigate, AdminDestination } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { RowActionMenu, type RowActionItem } from '../components/RowActionMenu';
import { CheckCircleIcon, MapPinIcon, PenLineIcon, TrashIcon } from '../components/Icons';
import { useI18n } from '../i18n';

const REGION_KEYS = ['', 'North', 'Central', 'South', 'West'] as const;

function DeleteDestinationButton({
  name,
  id,
  onDone,
  onError,
  compact,
}: {
  name: string;
  id: string;
  onDone: (msg: string) => void;
  onError: (msg: string) => void;
  compact?: boolean;
}) {
  const { t } = useI18n();

  const handleDelete = async () => {
    if (!window.confirm(t('common.confirmDeleteDestination', { name }))) return;
    try {
      await adminApi.deleteDestination(id);
      onDone(t('actions.deleted', { name }));
    } catch (e) {
      onError(e instanceof Error ? e.message : t('common.deleteFailed'));
    }
  };

  if (compact) {
    return (
      <button type="button" className="btn-danger-ghost" onClick={handleDelete}>
        <TrashIcon size={16} />
        {t('common.delete')}
      </button>
    );
  }

  return (
    <button type="button" className="btn-danger-outline" onClick={handleDelete}>
      <TrashIcon size={16} />
      {t('actions.deleteDestination')}
    </button>
  );
}

export function DestinationsPage() {
  const { t } = useI18n();
  const [items, setItems] = useState<AdminDestination[]>([]);
  const [view, setView] = useState<'active' | 'hidden'>('active');
  const [region, setRegion] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState('');
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    const request =
      view === 'hidden'
        ? adminApi.inactiveDestinations()
        : adminApi.adminDestinations({ region: region || undefined });
    request
      .then(setItems)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    const flash = sessionStorage.getItem('admin_flash');
    if (flash) {
      setToast(flash);
      sessionStorage.removeItem('admin_flash');
    }
  }, []);

  useEffect(() => { load(); }, [region, view]);

  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(t);
  }, [toast]);

  const restoreDestination = async (d: AdminDestination) => {
    try {
      await adminApi.restoreDestination(d.id);
      setToast(t('destinations.restored', { name: d.name }));
      load();
    } catch (e) {
      setToast(e instanceof Error ? e.message : t('common.actionFailed'));
    }
  };

  const menuItems = (d: AdminDestination): RowActionItem[] => {
    if (view === 'hidden') {
      return [
        {
          id: 'restore',
          label: t('destinations.restore'),
          icon: <CheckCircleIcon size={16} />,
          onClick: () => restoreDestination(d),
        },
      ];
    }
    return [
    {
      id: 'edit',
      label: t('actions.edit'),
      icon: <PenLineIcon size={16} />,
      onClick: () => adminNavigate(`destinations/edit/${d.id}`),
    },
    {
      id: 'delete',
      label: t('actions.deleteDestination'),
      icon: <TrashIcon size={16} />,
      tone: 'danger',
      onClick: async () => {
        if (!window.confirm(t('common.confirmDeleteDestination', { name: d.name }))) return;
        try {
          await adminApi.deleteDestination(d.id);
          setToast(t('actions.deleted', { name: d.name }));
          load();
        } catch (e) {
          setToast(e instanceof Error ? e.message : t('common.deleteFailed'));
        }
      },
      },
    ];
  };

  if (error) return <div className="admin-error">{error}</div>;

  const emptyMessage = view === 'hidden' ? t('destinations.hiddenEmpty') : t('destinations.empty');

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('destinations.title') }]} />
      <ContentToast message={toast} />
      <ContentPageHeader
        title={t('destinations.title')}
        description={t('destinations.description')}
        count={items.length}
        countLabel={t('destinations.countLabel')}
        actionLabel={view === 'active' ? t('destinations.create') : undefined}
        onAction={view === 'active' ? () => adminNavigate('destinations/new') : undefined}
      />

      <div className="content-toolbar">
        <div className="filter-chips">
          <button
            type="button"
            className={`filter-chip${view === 'active' ? ' active' : ''}`}
            onClick={() => setView('active')}
          >
            {t('destinations.tabActive')}
          </button>
          <button
            type="button"
            className={`filter-chip${view === 'hidden' ? ' active' : ''}`}
            onClick={() => setView('hidden')}
          >
            {t('destinations.tabHidden')}
          </button>
        </div>
        {view === 'active' && (
        <div className="filter-chips">
          {REGION_KEYS.map((value) => (
            <button
              key={value || 'all'}
              type="button"
              className={`filter-chip${region === value ? ' active' : ''}`}
              onClick={() => setRegion(value)}
            >
              {value ? t(`region.${value}`) : t('region.all')}
            </button>
          ))}
        </div>
        )}
      </div>

      {loading ? (
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      ) : items.length === 0 ? (
        <div className="content-empty card">
          <p>{emptyMessage}</p>
        </div>
      ) : (
        <div className="dest-grid">
          {items.map((d) => (
            <article key={d.id} className="dest-card asset-card">
              <div className="asset-card-menu">
                <RowActionMenu
                  open={openMenuId === d.id}
                  onToggle={() => setOpenMenuId((id) => (id === d.id ? null : d.id))}
                  onClose={() => setOpenMenuId(null)}
                  items={menuItems(d)}
                />
              </div>
              {d.imageUrl ? (
                <img src={d.imageUrl} alt="" className="dest-card-img" />
              ) : (
                <div className="dest-card-img dest-card-placeholder">
                  <MapPinIcon size={24} />
                </div>
              )}
              <div className="dest-card-body">
                <h3>{d.name}</h3>
                <p>{d.province} · {d.region}</p>
                <div className="dest-card-meta">
                  <span className="tag tag-cat tag-destination">{d.category}</span>
                  <span>{t('common.articlesCount', { count: d.articleCount })}</span>
                  <span>{d.estimatedCost.toLocaleString('vi-VN')} ₫</span>
                </div>
                <div className="dest-card-actions">
                  {view === 'hidden' ? (
                    <button type="button" className="btn-primary btn-sm" onClick={() => restoreDestination(d)}>
                      <CheckCircleIcon size={15} />
                      {t('destinations.restore')}
                    </button>
                  ) : (
                    <>
                  <button
                    type="button"
                    className="btn-secondary btn-sm"
                    onClick={() => adminNavigate(`destinations/edit/${d.id}`)}
                  >
                    <PenLineIcon size={15} />
                    {t('common.edit')}
                  </button>
                  <DeleteDestinationButton
                    compact
                    id={d.id}
                    name={d.name}
                    onDone={(msg) => {
                      setToast(msg);
                      load();
                    }}
                    onError={setToast}
                  />
                    </>
                  )}
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
