import type { ReactNode } from 'react';
import { adminApi, adminNavigate, type ArticleListItem } from '../api';
import { useI18n } from '../i18n';
import {
  CheckCircleIcon,
  ClockIcon,
  EyeIcon,
  PenLineIcon,
  TrashIcon,
} from '../components/Icons';
import type { RowActionItem } from '../components/RowActionMenu';
import { usePermissions } from '../context/PermissionsContext';

type ArticleActionOptions = {
  listNav?: 'articles' | 'news';
  onNotify: (message: string) => void;
  onViewDetail?: (row: ArticleListItem) => void;
  includeView?: boolean;
};

export function useArticleMenuItems() {
  const { t } = useI18n();
  const { canPublish } = usePermissions();

  const run = async (fn: () => Promise<void>, ok: string, onNotify: (m: string) => void) => {
    try {
      await fn();
      onNotify(ok);
    } catch (e) {
      onNotify(e instanceof Error ? e.message : t('common.actionFailed'));
    }
  };

  return (row: ArticleListItem, options: ArticleActionOptions): RowActionItem[] => {
    const { listNav, onNotify, onViewDetail, includeView } = options;
    const navType = listNav ?? (row.category === 'news' ? 'news' : 'articles');

    const items: RowActionItem[] = [];

    if (includeView && onViewDetail) {
      items.push({
        id: 'view',
        label: t('actions.viewDetail'),
        icon: <EyeIcon size={16} />,
        onClick: () => onViewDetail(row),
      });
    }

    items.push({
      id: 'edit',
      label: t('actions.edit'),
      icon: <PenLineIcon size={16} />,
      onClick: () => adminNavigate(`${navType}/edit/${row.id}`),
    });

    if (row.status !== 'published' && canPublish) {
      items.push({
        id: 'publish',
        label: t('actions.publish'),
        icon: <CheckCircleIcon size={16} />,
        onClick: () =>
          run(
            () => adminApi.publishArticle(row.id).then(() => undefined),
            t('actions.published', { name: row.title }),
            onNotify,
          ),
      });
    }

    if (row.status !== 'pending') {
      items.push({
        id: 'pending',
        label: t('actions.sendReview'),
        icon: <ClockIcon size={16} />,
        onClick: () =>
          run(
            () => adminApi.updateArticleStatus(row.id, 'pending').then(() => undefined),
            t('actions.sentReview', { name: row.title }),
            onNotify,
          ),
      });
    }

    if (includeView && row.status !== 'draft') {
      items.push({
        id: 'draft',
        label: t('actions.moveDraft'),
        icon: <PenLineIcon size={16} />,
        onClick: () =>
          run(
            () => adminApi.updateArticleStatus(row.id, 'draft').then(() => undefined),
            t('actions.movedDraft', { name: row.title }),
            onNotify,
          ),
      });
    }

    items.push({
      id: 'delete',
      label: includeView ? t('actions.deleteArticle') : t('common.delete'),
      icon: <TrashIcon size={16} />,
      tone: 'danger',
      onClick: () => {
        const msg = includeView
          ? t('common.confirmDeleteArticle', { name: row.title })
          : t('common.confirmDelete', { name: row.title });
        if (!window.confirm(msg)) return;
        run(
          () => adminApi.deleteArticle(row.id).then(() => undefined),
          t('actions.deleted', { name: row.title }),
          onNotify,
        );
      },
    });

    return items;
  };
}

export function useCrudMenuItems() {
  const { t } = useI18n();

  return {
    edit: (onClick: () => void, icon?: ReactNode): RowActionItem => ({
      id: 'edit',
      label: t('actions.edit'),
      icon,
      onClick,
    }),
    delete: (name: string, onConfirm: () => Promise<void>, onDone: (msg: string) => void, icon?: ReactNode): RowActionItem => ({
      id: 'delete',
      label: t('common.delete'),
      icon,
      tone: 'danger',
      onClick: async () => {
        if (!window.confirm(t('common.confirmDelete', { name }))) return;
        try {
          await onConfirm();
          onDone(t('actions.deleted', { name }));
        } catch (e) {
          onDone(e instanceof Error ? e.message : t('common.deleteFailed'));
        }
      },
    }),
  };
}
