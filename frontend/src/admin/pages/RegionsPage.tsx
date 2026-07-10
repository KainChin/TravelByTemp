import { useEffect, useState } from 'react';
import { adminApi, AdminDestination, adminNavigate } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader } from '../components/ContentPageHeader';
import { useI18n } from '../i18n';
import { PenLineIcon } from '../components/Icons';

const REGION_METADATA: Record<string, { descVi: string; descEn: string }> = {
  North: {
    descVi: 'Nơi lưu giữ hồn cốt ngàn năm văn hiến với thiên nhiên hùng vĩ và phong phú.',
    descEn: 'Northern Vietnam, characterized by towering highlands, rich culture, and historical depth.',
  },
  Central: {
    descVi: 'Nơi biển xanh, di sản cổ kính và vẻ đẹp thiên nhiên hòa quyện.',
    descEn: 'Central Vietnam, home to sandy beaches, old royal citadels, and beautiful caves.',
  },
  South: {
    descVi: 'Vùng đất năng động với biển đảo tuyệt đẹp và văn hóa đa dạng.',
    descEn: 'Southern Vietnam, dynamic economic centers and gorgeous tropical islands.',
  },
  West: {
    descVi: 'Vùng đất sông nước trù phú với văn hóa miệt vườn và ẩm thực đặc sắc.',
    descEn: 'Mekong Delta region, fertile waterways, floating markets, and orchard gardens.',
  },
};

export function RegionsPage() {
  const { t, locale } = useI18n();
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedRegion, setSelectedRegion] = useState<string | null>(null);

  useEffect(() => {
    adminApi
      .adminDestinations()
      .then(setDestinations)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  // Compute region statistics
  const regionStats = destinations.reduce((acc, curr) => {
    const reg = curr.region || 'Central';
    if (!acc[reg]) {
      acc[reg] = { name: reg, count: 0, items: [] };
    }
    acc[reg].count += 1;
    acc[reg].items.push(curr);
    return acc;
  }, {} as Record<string, { name: string; count: number; items: AdminDestination[] }>);

  // Pad missing regions in case there are none in DB
  const allRegions = ['North', 'Central', 'South', 'West'];
  allRegions.forEach((reg) => {
    if (!regionStats[reg]) {
      regionStats[reg] = { name: reg, count: 0, items: [] };
    }
  });

  const regionsList = Object.values(regionStats);

  if (error) return <div className="admin-error">{error}</div>;

  const activeRegionData = selectedRegion ? regionStats[selectedRegion] : null;

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('nav.regions') }]} />
      <ContentPageHeader
        title={t('nav.regions')}
        description={t('destinations.description')}
        count={regionsList.length}
        countLabel="vùng miền"
      />

      {loading ? (
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: selectedRegion ? '380px 1fr' : '1fr', gap: '1.5rem', transition: 'all 0.25s' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {regionsList.map((r) => {
              const meta = REGION_METADATA[r.name];
              const desc = locale === 'vi' ? meta?.descVi : meta?.descEn;
              const isSelected = selectedRegion === r.name;
              return (
                <div 
                  key={r.name} 
                  className={`card${isSelected ? ' active-card' : ''}`} 
                  style={{ 
                    cursor: 'pointer', 
                    border: isSelected ? '2px solid var(--brand)' : '1px solid var(--border)',
                    boxShadow: isSelected ? 'var(--shadow-md)' : undefined,
                    padding: '1.25rem'
                  }}
                  onClick={() => setSelectedRegion(isSelected ? null : r.name)}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                    <h3 style={{ fontSize: '1.05rem', fontWeight: 600, color: 'var(--ink)' }}>
                      {t(`region.${r.name}` as any)}
                    </h3>
                    <span className="tag tag-cat tag-destination" style={{ fontWeight: 'bold' }}>
                      {r.count} địa điểm
                    </span>
                  </div>
                  <p style={{ fontSize: '0.85rem', color: 'var(--ink-muted)', margin: 0, lineHeight: 1.5 }}>
                    {desc}
                  </p>
                </div>
              );
            })}
          </div>

          {activeRegionData && (
            <div className="card">
              <div className="card-header" style={{ marginBottom: '1.25rem' }}>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600 }}>
                  Địa điểm thuộc vùng: <span style={{ color: 'var(--brand-dark)', fontWeight: 'bold' }}>{t(`region.${selectedRegion}` as any)}</span>
                </h3>
              </div>
              {activeRegionData.items.length === 0 ? (
                <p style={{ color: 'var(--ink-muted)' }}>Chưa có địa điểm nào được tạo trong vùng này.</p>
              ) : (
                <div className="table-wrap">
                  <table className="admin-table">
                    <thead>
                      <tr>
                        <th>Tên địa điểm</th>
                        <th>Tỉnh/Thành</th>
                        <th>Danh mục</th>
                        <th style={{ textAlign: 'right' }}>Thao tác</th>
                      </tr>
                    </thead>
                    <tbody>
                      {activeRegionData.items.map((d) => (
                        <tr key={d.id}>
                          <td>
                            <strong>{d.name}</strong>
                          </td>
                          <td>{d.province}</td>
                          <td><span className="tag tag-cat tag-destination">{d.category}</span></td>
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
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
