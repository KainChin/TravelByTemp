import { CSSProperties } from 'react';
import { useI18n } from '../i18n';
import { PopularDestination, formatViewCount } from '../api';
import { EyeIcon } from './Icons';

export function PopularDestinations({ items }: { items: PopularDestination[] | null }) {
  const { t } = useI18n();
  if (!items) return <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>;

  return (
    <ul className="dest-list">
      {items.map((d, i) => (
        <li key={d.id} className="dest-item dest-enter" style={{ '--stagger': i } as CSSProperties}>
          {d.imageUrl && <img src={d.imageUrl} alt="" className="dest-thumb" />}
          <div className="dest-info">
            <span className="dest-name">{d.name}</span>
            <span className="dest-meta">
              <EyeIcon size={14} />
              {formatViewCount(d.viewCount)}
              <span className="dest-meta-sep">·</span>
              {t('common.articlesCount', { count: d.articleCount })}
            </span>
          </div>
        </li>
      ))}
    </ul>
  );
}
