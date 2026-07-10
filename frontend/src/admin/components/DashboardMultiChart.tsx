import { useState, CSSProperties } from 'react';
import { useI18n } from '../i18n';
import { ChartStat, DashboardChartStats } from '../api';

export function DashboardMultiChart({ data }: { data: DashboardChartStats | null }) {
  const { t } = useI18n();
  const [activeTab, setActiveTab] = useState<'regions' | 'categories' | 'articles'>('regions');

  if (!data) return <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>;

  const activeSet = data[activeTab] || [];
  
  const regionNames: Record<string, string> = {
    North: 'Miền Bắc',
    Central: 'Miền Trung',
    South: 'Miền Nam',
    West: 'Miền Tây',
  };

  const categoryNames: Record<string, string> = {
    Beach: 'Bãi biển',
    City: 'Thành phố',
    Mountain: 'Núi non',
    Nature: 'Thiên nhiên',
    Culture: 'Văn hóa',
  };

  const articleNames: Record<string, string> = {
    destination: 'Địa điểm',
    experience: 'Kinh nghiệm',
    news: 'Tin tức',
  };

  const getLabel = (key: string) => {
    if (activeTab === 'regions') return regionNames[key] || key;
    if (activeTab === 'categories') return categoryNames[key] || key;
    if (activeTab === 'articles') return articleNames[key] || key;
    return key;
  };

  const maxVal = Math.max(...activeSet.map((x) => x.count), 1);

  return (
    <div className="multi-chart-card">
      <div className="chart-tabs-bar" style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
        <button
          type="button"
          className={`filter-tab ${activeTab === 'regions' ? 'active' : ''}`}
          onClick={() => setActiveTab('regions')}
          style={{ width: 'auto', flex: 1, padding: '6px 12px', fontSize: '0.8125rem' }}
        >
          Vùng miền
        </button>
        <button
          type="button"
          className={`filter-tab ${activeTab === 'categories' ? 'active' : ''}`}
          onClick={() => setActiveTab('categories')}
          style={{ width: 'auto', flex: 1, padding: '6px 12px', fontSize: '0.8125rem' }}
        >
          Thể loại
        </button>
        <button
          type="button"
          className={`filter-tab ${activeTab === 'articles' ? 'active' : ''}`}
          onClick={() => setActiveTab('articles')}
          style={{ width: 'auto', flex: 1, padding: '6px 12px', fontSize: '0.8125rem' }}
        >
          Bài viết
        </button>
      </div>

      <div className="vertical-chart-container">
        <div className="chart-columns">
          {activeSet.map((item, i) => {
            const pct = (item.count / maxVal) * 80;
            const displayLabel = getLabel(item.key);
            return (
              <div key={item.key} className="chart-col">
                <div className="chart-bar-wrap">
                  <span className="chart-col-val">{item.count}</span>
                  <div
                    className="chart-bar-fill-vertical"
                    style={{
                      height: `${Math.max(pct, 5)}%`,
                      '--bar-delay': `${i * 0.05}s`
                    } as CSSProperties}
                  />
                </div>
                <div className="chart-col-label">{displayLabel}</div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
