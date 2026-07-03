import type { ReactNode } from 'react';
import { useI18n } from '../i18n';

type Props = {
  title: string;
  description: string;
  count?: number;
  countLabel?: string;
  actionLabel?: string;
  onAction?: () => void;
  children?: ReactNode;
};

export function ContentPageHeader({
  title,
  description,
  count,
  countLabel,
  actionLabel,
  onAction,
  children,
}: Props) {
  const { t, formatNumber } = useI18n();
  const label = countLabel ?? t('common.item');

  return (
    <div className="content-page-head">
      <div className="page-header content-page-intro">
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      <div className="content-page-actions">
        {count !== undefined && (
          <span className="count-badge">{formatNumber(count)} {label}</span>
        )}
        {actionLabel && onAction && (
          <button type="button" className="btn-primary" onClick={onAction}>
            {actionLabel}
          </button>
        )}
        {children}
      </div>
    </div>
  );
}

export function ContentToast({ message }: { message: string }) {
  if (!message) return null;
  return (
    <div className="content-toast" role="status">
      {message}
    </div>
  );
}

export function useAdminFlash() {
  const readFlash = () => {
    const flash = sessionStorage.getItem('admin_flash');
    if (flash) sessionStorage.removeItem('admin_flash');
    return flash ?? '';
  };
  return { readFlash };
}

export function setAdminFlash(message: string) {
  sessionStorage.setItem('admin_flash', message);
}
