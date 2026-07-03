import { useCallback, useEffect, useLayoutEffect, useRef, useState, type CSSProperties } from 'react';
import { AuthResponse, InboxSummary } from '../api';
import { useI18n } from '../i18n';
import {
  BellIcon,
  ChevronDownIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  LogoIcon,
  LogOutIcon,
  MenuIcon,
  NAV_ICON_MAP,
  SearchIcon,
} from './Icons';
import { LocaleSwitcher } from './LocaleSwitcher';

export const NAV_ITEMS = [
  { id: 'dashboard' },
  { id: 'destinations' },
  { id: 'articles' },
  { id: 'news' },
  { id: 'review' },
  { id: 'comments' },
  { id: 'banners' },
  { id: 'featured' },
  { id: 'gallery' },
  { id: 'users' },
] as const;

type Props = {
  active: string;
  collapsed: boolean;
  mobileOpen: boolean;
  visibleNavIds?: string[];
  onToggle: () => void;
  onLogout: () => void;
  onNavigate: (id: string) => void;
  onCloseMobile: () => void;
};

export function Sidebar({
  active,
  collapsed,
  mobileOpen,
  visibleNavIds,
  onToggle,
  onLogout,
  onNavigate,
  onCloseMobile,
}: Props) {
  const { t } = useI18n();
  const listRef = useRef<HTMLDivElement>(null);
  const itemRefs = useRef<Record<string, HTMLButtonElement | null>>({});
  const [indicator, setIndicator] = useState<{ top: number; height: number } | null>(null);

  const updateIndicator = useCallback(() => {
    const btn = itemRefs.current[active];
    const list = listRef.current;
    if (!btn || !list || collapsed) {
      setIndicator(null);
      return;
    }
    setIndicator({ top: btn.offsetTop, height: btn.offsetHeight });
  }, [active, collapsed]);

  useLayoutEffect(() => {
    updateIndicator();
    const list = listRef.current;
    if (!list) return;

    const ro = new ResizeObserver(updateIndicator);
    ro.observe(list);
    NAV_ITEMS.forEach((item) => {
      const el = itemRefs.current[item.id];
      if (el) ro.observe(el);
    });

    return () => ro.disconnect();
  }, [updateIndicator]);

  useLayoutEffect(() => {
    const btn = itemRefs.current[active];
    btn?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  }, [active]);

  return (
    <>
      {mobileOpen && (
        <button
          type="button"
          className="sidebar-backdrop"
          aria-label={t('sidebar.closeMenu')}
          onClick={onCloseMobile}
        />
      )}
      <aside
        className={`admin-sidebar${collapsed ? ' collapsed' : ''}${mobileOpen ? ' mobile-open' : ''}`}
      >
        <div className="sidebar-brand">
          <span className="brand-icon-wrap">
            <LogoIcon size={22} />
          </span>
          {!collapsed && (
            <div className="brand-copy">
              <span className="brand-text">{t('brand.title')}</span>
              <span className="brand-sub">{t('brand.subtitle')}</span>
            </div>
          )}
        </div>

        <nav className="sidebar-nav">
          <div className="nav-list" ref={listRef}>
            {indicator && !collapsed && (
              <div
                className="nav-indicator"
                aria-hidden="true"
                style={
                  {
                    '--indicator-top': `${indicator.top}px`,
                    '--indicator-height': `${indicator.height}px`,
                  } as CSSProperties
                }
              />
            )}
            {(visibleNavIds ? NAV_ITEMS.filter((i) => visibleNavIds.includes(i.id)) : NAV_ITEMS).map((item) => {
              const Icon = NAV_ICON_MAP[item.id];
              const isActive = active === item.id;
              return (
                <button
                  key={item.id}
                  ref={(el) => {
                    itemRefs.current[item.id] = el;
                  }}
                  type="button"
                  className={`nav-item${isActive ? ' active' : ''}`}
                  onClick={() => onNavigate(item.id)}
                  aria-current={isActive ? 'page' : undefined}
                >
                  <span className="nav-icon">
                    <Icon size={18} />
                  </span>
                  {!collapsed && <span className="nav-label">{t(`nav.${item.id}`)}</span>}
                </button>
              );
            })}
          </div>
        </nav>

        {!collapsed && (
          <div className="sidebar-locale">
            <LocaleSwitcher compact />
          </div>
        )}

        <button type="button" className="sidebar-logout" onClick={onLogout}>
          <LogOutIcon size={18} />
          {!collapsed && <span>{t('sidebar.logout')}</span>}
        </button>

        <button type="button" className="sidebar-collapse-btn" onClick={onToggle} aria-label={t('sidebar.collapse')}>
          {collapsed ? <ChevronRightIcon size={16} /> : <ChevronLeftIcon size={16} />}
        </button>
      </aside>
    </>
  );
}

export function Header({
  auth,
  onMenuToggle,
  searchQuery,
  onSearchChange,
  onSearch,
  inbox,
  onNavigate,
  canSeeReview,
  visibleNavIds,
  onLogout,
}: {
  auth: AuthResponse;
  onMenuToggle: () => void;
  searchQuery: string;
  onSearchChange: (v: string) => void;
  onSearch: (q: string) => void;
  inbox: InboxSummary | null;
  onNavigate: (route: string) => void;
  canSeeReview: boolean;
  visibleNavIds: string[];
  onLogout: () => void;
}) {
  const { t, formatNumber } = useI18n();
  const roleLabel = auth.user.role === 'Admin' ? t('roles.admin') : t('roles.contentManager');
  const [inboxOpen, setInboxOpen] = useState(false);
  const [userOpen, setUserOpen] = useState(false);
  const inboxRef = useRef<HTMLDivElement>(null);
  const userRef = useRef<HTMLDivElement>(null);

  const pendingArticles = inbox?.pendingArticles ?? 0;
  const pendingComments = inbox?.pendingComments ?? 0;
  const totalInbox = pendingArticles + pendingComments;

  useEffect(() => {
    if (!inboxOpen && !userOpen) return;
    const close = (e: MouseEvent) => {
      const target = e.target as Node;
      if (inboxOpen && inboxRef.current && !inboxRef.current.contains(target)) {
        setInboxOpen(false);
      }
      if (userOpen && userRef.current && !userRef.current.contains(target)) {
        setUserOpen(false);
      }
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [inboxOpen, userOpen]);

  const goInbox = useCallback(
    (route: string) => {
      setInboxOpen(false);
      onNavigate(route);
    },
    [onNavigate],
  );

  const goUser = useCallback(
    (route: string) => {
      setUserOpen(false);
      onNavigate(route);
    },
    [onNavigate],
  );

  const profileLinks = [
    { id: 'dashboard', label: t('userMenu.dashboard') },
    { id: 'activity', label: t('userMenu.activity') },
    ...(visibleNavIds.includes('review') ? [{ id: 'review', label: t('userMenu.review') }] : []),
    ...(visibleNavIds.includes('users') ? [{ id: 'users', label: t('userMenu.users') }] : []),
  ];

  return (
    <header className="admin-header">
      <button type="button" className="header-menu-btn icon-btn" onClick={onMenuToggle} aria-label={t('header.menu')}>
        <MenuIcon size={20} />
      </button>

      <form
        className="header-search"
        onSubmit={(e) => {
          e.preventDefault();
          onSearch(searchQuery);
        }}
      >
        <SearchIcon size={18} className="search-icon-svg" />
        <input
          type="search"
          placeholder={t('header.searchPlaceholder')}
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
        />
      </form>

      <div className="header-actions">
        <LocaleSwitcher compact />
        <div className="inbox-wrap" ref={inboxRef}>
          <button
            type="button"
            className={`icon-btn notif-btn${inboxOpen ? ' active' : ''}`}
            aria-label={t('header.notifications')}
            aria-expanded={inboxOpen}
            onClick={() => {
              setUserOpen(false);
              setInboxOpen((v) => !v);
            }}
          >
            <BellIcon size={20} />
            {totalInbox > 0 && (
              <span className="notif-badge">{totalInbox > 9 ? '9+' : totalInbox}</span>
            )}
          </button>
          {inboxOpen && (
            <div className="inbox-dropdown" role="menu">
              <p className="inbox-dropdown-title">{t('inbox.title')}</p>
              {totalInbox === 0 ? (
                <p className="inbox-empty">{t('inbox.empty')}</p>
              ) : (
                <ul className="inbox-list">
                  {pendingArticles > 0 && (
                    <li>
                      <button
                        type="button"
                        className="inbox-item"
                        onClick={() => goInbox(canSeeReview ? 'review' : 'articles')}
                      >
                        <span>{t('inbox.pendingArticles', { count: formatNumber(pendingArticles) })}</span>
                      </button>
                    </li>
                  )}
                  {pendingComments > 0 && (
                    <li>
                      <button type="button" className="inbox-item" onClick={() => goInbox('comments')}>
                        <span>{t('inbox.pendingComments', { count: formatNumber(pendingComments) })}</span>
                      </button>
                    </li>
                  )}
                </ul>
              )}
            </div>
          )}
        </div>
        <div className="user-menu-wrap" ref={userRef}>
          <button
            type="button"
            className={`user-menu${userOpen ? ' active' : ''}`}
            aria-expanded={userOpen}
            aria-haspopup="menu"
            onClick={() => {
              setInboxOpen(false);
              setUserOpen((v) => !v);
            }}
          >
            <img
              src={`https://i.pravatar.cc/80?u=${auth.user.username}`}
              alt=""
              className="user-avatar"
            />
            <div className="user-info">
              <span className="user-name">{auth.user.fullName}</span>
              <span className="user-role">@{auth.user.username}</span>
            </div>
            <ChevronDownIcon size={16} className={`user-chevron${userOpen ? ' open' : ''}`} />
          </button>
          {userOpen && (
            <div className="user-dropdown" role="menu">
              <div className="user-dropdown-head">
                <img
                  src={`https://i.pravatar.cc/80?u=${auth.user.username}`}
                  alt=""
                  className="user-dropdown-avatar"
                />
                <strong>{auth.user.fullName}</strong>
                <dl className="user-dropdown-meta">
                  <div>
                    <dt>{t('userMenu.username')}</dt>
                    <dd>@{auth.user.username}</dd>
                  </div>
                  <div>
                    <dt>{t('userMenu.email')}</dt>
                    <dd>{auth.user.email}</dd>
                  </div>
                  <div>
                    <dt>{t('userMenu.role')}</dt>
                    <dd><span className="user-dropdown-role">{roleLabel}</span></dd>
                  </div>
                </dl>
              </div>
              <ul className="user-dropdown-list">
                {profileLinks.map((link) => (
                  <li key={link.id}>
                    <button
                      type="button"
                      className="user-dropdown-item"
                      onClick={() => goUser(link.id)}
                    >
                      {link.label}
                    </button>
                  </li>
                ))}
                <li className="user-dropdown-divider" aria-hidden />
                <li>
                  <button
                    type="button"
                    className="user-dropdown-item danger"
                    onClick={() => {
                      setUserOpen(false);
                      onLogout();
                    }}
                  >
                    <LogOutIcon size={16} />
                    {t('userMenu.logout')}
                  </button>
                </li>
              </ul>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
