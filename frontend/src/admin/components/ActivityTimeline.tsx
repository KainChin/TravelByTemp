import type { CSSProperties } from 'react';
import type { ActivityLog } from '../api';
import { useI18n } from '../i18n';
import {
  CheckCircleIcon,
  MapPinIcon,
  PenLineIcon,
  TrashIcon,
} from './Icons';

function iconFor(actionType: string) {
  if (actionType.includes('publish')) return CheckCircleIcon;
  if (actionType.includes('destination')) return MapPinIcon;
  if (actionType.includes('delete')) return TrashIcon;
  if (actionType.includes('create')) return PenLineIcon;
  return PenLineIcon;
}

type Props = {
  items: ActivityLog[] | null;
  loading?: boolean;
  emptyMessage?: string;
};

export function ActivityTimeline({ items, loading, emptyMessage }: Props) {
  const { t, formatTimeAgo } = useI18n();

  if (loading || items === null) {
    return (
      <div className="card-loading">
        <span className="loading-dots">{t('common.loading')}</span>
      </div>
    );
  }

  if (items.length === 0) {
    return <p className="content-muted activity-empty">{emptyMessage ?? t('activity.empty')}</p>;
  }

  return (
    <ul className="activity-list">
      {items.map((a, i) => {
        const Icon = iconFor(a.actionType);
        return (
          <li key={a.id} className="activity-item activity-enter" style={{ '--stagger': i } as CSSProperties}>
            <span className={`activity-icon tone-${a.actionType.split('_')[0]}`}>
              <Icon size={16} />
            </span>
            <div className="activity-body">
              <p className="activity-desc">{a.description}</p>
              <span className="activity-meta">
                {a.userName} · {formatTimeAgo(a.createdAt)}
              </span>
            </div>
          </li>
        );
      })}
    </ul>
  );
}
