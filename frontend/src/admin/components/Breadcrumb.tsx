import { Link } from 'react-router-dom';
import { useI18n } from '../i18n';
import { ChevronRightIcon } from './Icons';

export type BreadcrumbItem = { label: string; to?: string };

export function Breadcrumb({ items }: { items: BreadcrumbItem[] }) {
  const { t } = useI18n();
  if (items.length === 0) return null;

  return (
    <nav className="admin-breadcrumb" aria-label={t('common.breadcrumb')}>
      <Link to="/admin">{t('nav.dashboard')}</Link>
      {items.map((item, i) => (
        <span key={`${item.label}-${i}`} className="admin-breadcrumb-segment">
          <ChevronRightIcon size={14} aria-hidden />
          {item.to ? <Link to={item.to}>{item.label}</Link> : <span aria-current="page">{item.label}</span>}
        </span>
      ))}
    </nav>
  );
}
