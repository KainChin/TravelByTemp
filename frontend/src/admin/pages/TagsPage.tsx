import { useEffect, useState } from 'react';
import { adminApi, AdminDestination, adminNavigate } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader } from '../components/ContentPageHeader';
import { useI18n } from '../i18n';
import { PenLineIcon } from '../components/Icons';

export function TagsPage() {
  const { t } = useI18n();
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedTag, setSelectedTag] = useState<string | null>(null);

  useEffect(() => {
    adminApi
      .adminDestinations()
      .then(setDestinations)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  // Compute tag statistics based on travel styles, suitable weather, and category
  // Since we don't have tags array in C# Destination model directly, we extract tags from 'Category' and 'travel_style' (from detailed model or category strings)
  const tagStats = destinations.reduce((acc, curr) => {
    const tags = [curr.category];
    // Add additional tag tokens if any
    const words = curr.name.split(' ');
    if (words.length > 0 && curr.category.toLowerCase() !== words[0].toLowerCase()) {
      // Just some sample dynamic tag logic based on values
    }
    
    tags.forEach((tag) => {
      if (!tag) return;
      const formattedTag = tag.trim();
      if (!acc[formattedTag]) {
        acc[formattedTag] = { name: formattedTag, count: 0, items: [] };
      }
      acc[formattedTag].count += 1;
      acc[formattedTag].items.push(curr);
    });
    return acc;
  }, {} as Record<string, { name: string; count: number; items: AdminDestination[] }>);

  const tagsList = Object.values(tagStats).sort((a, b) => b.count - a.count);

  if (error) return <div className="admin-error">{error}</div>;

  const activeTagData = selectedTag ? tagStats[selectedTag] : null;

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('nav.tags') }]} />
      <ContentPageHeader
        title={t('nav.tags')}
        description={t('destinations.description')}
        count={tagsList.length}
        countLabel="thẻ"
      />

      {loading ? (
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: selectedTag ? '300px 1fr' : '1fr', gap: '1.5rem', transition: 'all 0.25s' }}>
          <div className="card" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontSize: '0.9375rem', fontWeight: 600, marginBottom: '1rem', color: 'var(--ink)' }}>Tags đám mây</h3>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
              {tagsList.map((tag) => {
                const isSelected = selectedTag === tag.name;
                // Calculate font sizes dynamically for visual "tag cloud" effect!
                const fontSize = Math.max(12, Math.min(22, 12 + tag.count * 2));
                return (
                  <button
                    key={tag.name}
                    type="button"
                    style={{
                      border: isSelected ? '1px solid var(--brand)' : '1px solid var(--border)',
                      background: isSelected ? 'var(--brand-soft)' : 'var(--bg)',
                      color: isSelected ? 'var(--brand-dark)' : 'var(--ink-muted)',
                      padding: '0.35rem 0.65rem',
                      borderRadius: '16px',
                      cursor: 'pointer',
                      fontSize: `${fontSize}px`,
                      fontWeight: isSelected ? 'bold' : 'normal',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.35rem',
                      transition: 'all 0.15s'
                    }}
                    onClick={() => setSelectedTag(isSelected ? null : tag.name)}
                  >
                    #{tag.name}
                    <span style={{ fontSize: '10px', opacity: 0.7 }}>({tag.count})</span>
                  </button>
                );
              })}
            </div>
          </div>

          {activeTagData && (
            <div className="card">
              <div className="card-header" style={{ marginBottom: '1.25rem' }}>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600 }}>
                  Địa điểm được gắn thẻ: <span style={{ color: 'var(--brand-dark)', fontWeight: 'bold' }}>#{selectedTag}</span>
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
                    {activeTagData.items.map((d) => (
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
