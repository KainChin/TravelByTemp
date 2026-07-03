import { useEffect, useId, useRef, type ReactNode } from 'react';
import { useI18n } from '../i18n';
import { MoreVerticalIcon } from './Icons';

export type RowActionItem = {
  id: string;
  label: string;
  icon?: ReactNode;
  tone?: 'default' | 'danger';
  disabled?: boolean;
  onClick: () => void;
};

type Props = {
  open: boolean;
  onToggle: () => void;
  onClose: () => void;
  items: RowActionItem[];
  label?: string;
};

export function RowActionMenu({ open, onToggle, onClose, items, label }: Props) {
  const { t } = useI18n();
  const menuLabel = label ?? t('common.options');
  const menuId = useId();
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;

    const onPointerDown = (e: MouseEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) onClose();
    };
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };

    document.addEventListener('mousedown', onPointerDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('mousedown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [open, onClose]);

  useEffect(() => {
    const host = rootRef.current?.closest('tr, .dest-card, .asset-card, article');
    if (!host) return;
    if (open) host.classList.add('menu-open-row');
    else host.classList.remove('menu-open-row');
    return () => host.classList.remove('menu-open-row');
  }, [open]);

  return (
    <div className="row-action-menu" ref={rootRef}>
      <button
        type="button"
        className={`icon-btn row-menu-btn${open ? ' active' : ''}`}
        aria-label={menuLabel}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={menuId}
        onClick={onToggle}
      >
        <MoreVerticalIcon size={18} />
      </button>
      {open && (
        <div className="row-action-dropdown" id={menuId} role="menu">
          {items.map((item) => (
            <button
              key={item.id}
              type="button"
              role="menuitem"
              className={`row-action-item${item.tone === 'danger' ? ' danger' : ''}`}
              disabled={item.disabled}
              onClick={() => {
                item.onClick();
                onClose();
              }}
            >
              {item.icon && <span className="row-action-icon">{item.icon}</span>}
              {item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
