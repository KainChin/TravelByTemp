import type { ReactNode } from 'react';
import { useI18n } from '../i18n';

type Props = {
  title: string;
  open: boolean;
  saving?: boolean;
  onClose: () => void;
  onSave: () => void;
  children: ReactNode;
};

export function EditorModal({ title, open, saving, onClose, onSave, children }: Props) {
  const { t } = useI18n();
  if (!open) return null;

  return (
    <div className="admin-modal-backdrop" onClick={onClose} role="presentation">
      <div
        className="admin-modal admin-modal-wide"
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="admin-modal-header">
          <h2>{title}</h2>
          <button type="button" className="icon-btn" onClick={onClose} aria-label={t('common.close')}>
            ×
          </button>
        </div>
        <div className="admin-modal-body">{children}</div>
        <div className="editor-actions editor-modal-actions">
          <button type="button" className="btn-secondary" onClick={onClose} disabled={saving}>
            {t('common.cancel')}
          </button>
          <button type="button" className="btn-primary" onClick={onSave} disabled={saving}>
            {saving ? t('common.saving') : t('common.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
