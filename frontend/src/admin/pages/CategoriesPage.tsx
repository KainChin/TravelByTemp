import { useEffect, useState } from 'react';
import { adminApi, AdminDestination, adminNavigate } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader } from '../components/ContentPageHeader';
import { useI18n } from '../i18n';
import { PenLineIcon } from '../components/Icons';

export function CategoriesPage() {
  const { t } = useI18n();
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  useEffect(() => {
    adminApi
      .adminDestinations()
      .then(setDestinations)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  // Compute category statistics
  const categoryStats = destinations.reduce((acc, curr) => {
    const cat = curr.category || 'Uncategorized';
    if (!acc[cat]) {
      acc[cat] = { name: cat, count: 0, items: [] };
    }
    acc[cat].count += 1;
    acc[cat].items.push(curr);
    return acc;
  }, {} as Record<string, { name: string; count: number; items: AdminDestination[] }>);

  const categoriesList = Object.values(categoryStats).sort((a, b) => b.count - a.count);

  if (error) return <div className="admin-error">{error}</div>;

  const activeCategoryData = selectedCategory ? categoryStats[selectedCategory] : null;

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('nav.categories') }]} />
      <ContentPageHeader
        title={t('nav.categories')}
        description={t('destinations.description')}
        count={categoriesList.length}
        countLabel="danh mục"
      />

      {loading ? (
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: selectedCategory ? '320px 1fr' : '1fr', gap: '1.5rem', transition: 'all 0.25s' }}>
          <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
            <table className="admin-table">
              <thead>
                <tr>
                  <th>{t('table.category')}</th>
                  <th style={{ textAlign: 'center' }}>Số địa điểm</th>
                </tr>
              </thead>
              <tbody>
                {categoriesList.map((c) => (
                  <tr 
                    key={c.name} 
                    style={{ cursor: 'pointer', background: selectedCategory === c.name ? 'var(--brand-soft)' : undefined }}
                    onClick={() => setSelectedCategory(selectedCategory === c.name ? null : c.name)}
                  >
                    <td>
                      <span className="tag tag-cat tag-destination">{c.name}</span>
                    </td>
                    <td style={{ textAlign: 'center', fontWeight: 'bold' }}>{c.count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {activeCategoryData && (
            <div className="card">
              <div className="card-header" style={{ marginBottom: '1.25rem' }}>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600 }}>
                  Địa điểm thuộc danh mục: <span className="tag tag-cat tag-destination">{selectedCategory}</span>
                </h3>
              </div>
              <div className="table-wrap">
                <table className="admin-table">
                  <thead>
                    <tr>
                      <th>Tên địa điểm</th>
                      <th>Tỉnh/Thành</th>
                      <th>Vùng miền</th>
                      <th style={{ textAlign: 'right' }}>Thao tác</th>
                    </tr>
                  </thead>
                  <tbody>
                    {activeCategoryData.items.map((d) => (
                      <tr key={d.id}>
                        <td>
                          <strong>{d.name}</strong>
                        </td>
                        <td>{d.province}</td>
                        <td>{t(`region.${d.region}` as any)}</td>
                        <td style={{ textAlign: 'right' }}>
                          <button
                            type="button"
                            className="btn-secondary btn-sm"
                            style={{ cursor: 'pointer' }}
                            onClick={() => adminNavigate(`destinations/edit/${d.id}`)}
                          >
                            <PenLineIcon size={14} />
                            {t('common.edit')}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
