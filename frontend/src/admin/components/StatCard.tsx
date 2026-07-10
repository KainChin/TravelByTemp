import { CSSProperties } from 'react';
import { useI18n } from '../i18n';
import { DashboardStat } from '../api';
import { STAT_ICON_MAP, TrendingDownIcon, TrendingUpIcon } from './Icons';

export function StatCard({
  stat,
  index,
  onNavigate,
}: {
  stat: DashboardStat;
  index: number;
  onNavigate?: (route: string) => void;
}) {
  const { t, formatNumber } = useI18n();
  const Icon = STAT_ICON_MAP[stat.key as keyof typeof STAT_ICON_MAP] ?? STAT_ICON_MAP.totalArticles;
  const TrendIcon = stat.changePercent >= 0 ? TrendingUpIcon : TrendingDownIcon;
  const labelKey = `dashboard.stats.${stat.key}`;
  const label = t(labelKey) === labelKey ? stat.label : t(labelKey);
  const routeMap: Record<string, string> = {
    totalArticles: 'articles',
    publishedArticles: 'articles',
    draftArticles: 'articles',
    travelNews: 'news',
    destinations: 'destinations',
    featuredDestinations: 'featured',
    pending: 'review',
    mediaCount: 'gallery',
  };
  const targetRoute = routeMap[stat.key];

  return (
    <div
      className={`stat-card stat-${stat.iconColor} stat-enter${targetRoute && onNavigate ? ' stat-clickable' : ''}`}
      style={{ '--stagger': index } as CSSProperties}
      role={targetRoute && onNavigate ? 'button' : undefined}
      tabIndex={targetRoute && onNavigate ? 0 : undefined}
      onClick={targetRoute && onNavigate ? () => onNavigate(targetRoute) : undefined}
      onKeyDown={
        targetRoute && onNavigate
          ? (e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                onNavigate(targetRoute);
              }
            }
          : undefined
      }
    >
      <div className="stat-icon">
        <Icon size={20} />
      </div>
      <div className="stat-body">
        <span className="stat-label">{label}</span>
        <span className="stat-value">{formatNumber(stat.count)}</span>
        <span className={`stat-change${stat.changePercent >= 0 ? ' up' : ' down'}`}>
          <TrendIcon size={14} />
          {t('common.changeVsLastMonth', { percent: Math.abs(stat.changePercent) })}
        </span>
      </div>
    </div>
  );
}
