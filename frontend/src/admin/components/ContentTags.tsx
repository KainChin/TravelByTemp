import { useI18n } from '../i18n';

export function StatusTag({ status }: { status: string }) {
  const { t } = useI18n();
  const label = t(`status.${status}`);
  return <span className={`tag tag-status tag-${status}`}>{label === `status.${status}` ? status : label}</span>;
}

export function CategoryTag({ category }: { category: string }) {
  const { t } = useI18n();
  const label = t(`category.${category}`);
  return <span className={`tag tag-cat tag-${category}`}>{label === `category.${category}` ? category : label}</span>;
}

export function AuthorCell({ name }: { name: string }) {
  const initial = name.trim().charAt(0).toUpperCase() || '?';
  return (
    <div className="author-cell">
      <span className="author-avatar author-avatar-fallback" aria-hidden="true">
        {initial}
      </span>
      <span>{name}</span>
    </div>
  );
}
