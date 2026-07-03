import { FormEvent, useEffect, useState } from 'react';

import { adminApi, AuthResponse, SearchResult, adminModuleFromRoute, adminNavigate, parseAdminRoute, setAdminUnauthorizedHandler, type InboxSummary } from './api';

import { Header, Sidebar } from './components/Layout';

import { LockIcon, LogoIcon, UserIcon } from './components/Icons';

import { LocaleSwitcher } from './components/LocaleSwitcher';

import { PageTransition } from './components/PageTransition';

import { I18nProvider, useI18n } from './i18n';

import { DashboardPage } from './pages/DashboardPage';

import { ArticlesPage } from './pages/ArticlesPage';

import { ArticleEditorPage } from './pages/ArticleEditorPage';

import { DestinationEditorPage } from './pages/DestinationEditorPage';
import { DestinationsPage } from './pages/DestinationsPage';
import { BannersPage } from './pages/BannersPage';

import { FeaturedPage } from './pages/FeaturedPage';

import { GalleryPage } from './pages/GalleryPage';

import { ReviewPage } from './pages/ReviewPage';

import { CommentsPage } from './pages/CommentsPage';

import { UsersPage } from './pages/UsersPage';

import { ActivityPage } from './pages/ActivityPage';

import { PermissionsProvider } from './context/PermissionsContext';

import './admin.css';



function LoginPage({ onLogin }: { onLogin: (auth: AuthResponse) => void }) {

  const { t } = useI18n();
  const isDev = import.meta.env.DEV;

  const [username, setUsername] = useState(isDev ? 'manager' : '');

  const [password, setPassword] = useState(isDev ? 'Manager@123' : '');

  const [error, setError] = useState('');

  const [loading, setLoading] = useState(false);



  const submit = async (e: FormEvent) => {

    e.preventDefault();

    setLoading(true);

    setError('');

    try {

      const auth = await adminApi.login(username, password);

      if (auth.user.role !== 'TravelManager' && auth.user.role !== 'Admin') {

        adminApi.logout();

        throw new Error(t('login.noAccess'));

      }

      onLogin(auth);

    } catch (err) {

      setError(err instanceof Error ? err.message : t('common.loginFailed'));

    } finally {

      setLoading(false);

    }

  };



  return (

    <div className="admin-login">

      <div className="login-visual">

        <div className="login-visual-bg" />

        <div className="login-visual-content">

          <div className="login-visual-logo">

            <LogoIcon size={28} />

          </div>

          <h2>{t('login.heroTitle')}</h2>

          <p>{t('login.heroDesc')}</p>

          <ul className="login-features">

            <li>{t('login.feature1')}</li>

            <li>{t('login.feature2')}</li>

            <li>{t('login.feature3')}</li>

          </ul>

        </div>

      </div>



      <div className="login-panel">

        <form className="login-card login-enter" onSubmit={submit}>

          <div className="login-brand">

            <span className="login-brand-icon">

              <LogoIcon size={24} />

            </span>

            <div>

              <h1>{t('brand.title')}</h1>

              <p>{t('login.continue')}</p>

            </div>

          </div>



          {error && (

            <div className="login-error" role="alert">

              {error}

            </div>

          )}



          <label className="field">

            <span className="field-label">{t('login.username')}</span>

            <span className="field-input-wrap">

              <UserIcon size={18} className="field-icon" />

              <input

                value={username}

                onChange={(e) => setUsername(e.target.value)}

                autoComplete="username"

                placeholder={isDev ? 'manager' : t('login.usernamePlaceholder')}

              />

            </span>

          </label>



          <label className="field">

            <span className="field-label">{t('login.password')}</span>

            <span className="field-input-wrap">

              <LockIcon size={18} className="field-icon" />

              <input

                type="password"

                value={password}

                onChange={(e) => setPassword(e.target.value)}

                autoComplete="current-password"

                placeholder="••••••••"

              />

            </span>

          </label>



          <button type="submit" className="login-submit" disabled={loading}>

            {loading ? (

              <>

                <span className="btn-spinner" aria-hidden="true" />

                {t('login.submitting')}

              </>

            ) : (

              t('login.submit')

            )}

          </button>



          <LocaleSwitcher />

          {isDev && (
            <p className="login-hint">
              {t('login.demoHint')} <code>manager</code> / <code>Manager@123</code>
            </p>
          )}

        </form>

      </div>

    </div>

  );

}



function flashAndNavigate(route: string, message: string) {

  sessionStorage.setItem('admin_flash', message);

  adminNavigate(route);

}



export default function AdminApp() {
  return (
    <I18nProvider>
      <AdminShell />
    </I18nProvider>
  );
}

function AdminShell() {

  const { t } = useI18n();

  const [auth, setAuth] = useState<AuthResponse | null>(() => adminApi.getAuth());

  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const [searchQuery, setSearchQuery] = useState('');

  const [searchResults, setSearchResults] = useState<SearchResult[] | null>(null);

  const [route, setRoute] = useState(parseAdminRoute);

  const [enterShell, setEnterShell] = useState(false);
  const [visibleNavIds, setVisibleNavIds] = useState<string[]>([
    'dashboard', 'destinations', 'articles', 'news', 'banners', 'featured', 'gallery',
  ]);
  const [permissions, setPermissions] = useState({
    canPublish: false,
    isAdmin: false,
    role: 'Content Manager',
  });
  const [inbox, setInbox] = useState<InboxSummary | null>(null);

  const activeNav = adminModuleFromRoute(route);

  const PERM_NAV: Record<string, string> = {
    manage_destinations: 'destinations',
    manage_articles: 'articles',
    manage_news: 'news',
    manage_banners: 'banners',
    manage_gallery: 'gallery',
    manage_featured: 'featured',
    approve_content: 'review',
    moderate_comments: 'comments',
    manage_users: 'users',
  };



  useEffect(() => {

    setAdminUnauthorizedHandler(() => {

      adminApi.logout();

      setAuth(null);

    });

  }, []);



  useEffect(() => {

    const syncRoute = () => setRoute(parseAdminRoute());

    syncRoute();

    if (window.location.hash.startsWith('#')) {
      const legacy = window.location.hash.replace('#', '');
      if (legacy && window.location.pathname.match(/^\/admin\/?$/)) {
        window.history.replaceState(null, '', `/admin/${legacy}`);
        syncRoute();
      }
    }

    window.addEventListener('popstate', syncRoute);

    return () => window.removeEventListener('popstate', syncRoute);

  }, []);



  useEffect(() => {
    if (!auth) return;
    adminApi.permissions().then((p) => {
      const ids = ['dashboard'];
      p.permissions.filter((x) => x.granted).forEach((perm) => {
        const nav = PERM_NAV[perm.key];
        if (nav && !ids.includes(nav)) ids.push(nav);
      });
      setVisibleNavIds(ids);
      setPermissions({
        canPublish: p.canPublish,
        isAdmin: p.role === 'Admin',
        role: p.role,
      });
    }).catch(() => {});
    adminApi.inboxSummary().then(setInbox).catch(() => {});
  }, [auth, route]);

  useEffect(() => {
    if (auth) {
      requestAnimationFrame(() => setEnterShell(true));
    } else {
      setEnterShell(false);
    }
  }, [auth]);



  const handleNavigate = (id: string) => {
    adminNavigate(id);
    setRoute(parseAdminRoute());
    setMobileNavOpen(false);
  };



  const handleSearch = async (q: string) => {

    if (!q.trim()) {

      setSearchResults(null);

      return;

    }

    try {

      const res = await adminApi.search(q);

      setSearchResults(res.results);

    } catch {

      setSearchResults([]);

    }

  };



  const handleSearchSelect = (result: SearchResult) => {

    setSearchResults(null);

    setSearchQuery('');

    if (result.entityType === 'article') {

      flashAndNavigate(`articles/edit/${result.id}`, t('login.openFromSearchArticle'));

    } else if (result.entityType === 'destination') {
      flashAndNavigate(`destinations/edit/${result.id}`, t('login.openFromSearchDestination'));

    }

  };



  if (!auth) {

    return <LoginPage onLogin={setAuth} />;

  }



  const renderArticlesModule = (

    listNav: 'articles' | 'news',

    articleType: 'article' | 'news',

    listTitle: string,

    description: string,

  ) => {

    const parts = route.split('/');

    if (parts[1] === 'new') {

      return (

        <ArticleEditorPage

          articleType={articleType}

          listNav={listNav}

          listTitle={listTitle}

          onBack={() => adminNavigate(listNav)}

          onSaved={(msg) => flashAndNavigate(listNav, msg)}

        />

      );

    }

    if (parts[1] === 'edit' && parts[2]) {

      return (

        <ArticleEditorPage

          articleType={articleType}

          listNav={listNav}

          listTitle={listTitle}

          articleId={parts[2]}

          onBack={() => adminNavigate(listNav)}

          onSaved={(msg) => flashAndNavigate(listNav, msg)}

          onDeleted={(msg) => flashAndNavigate(listNav, msg)}

        />

      );

    }

    return (

      <ArticlesPage

        title={listTitle}

        description={description}

        articleType={articleType}

        listNav={listNav}

      />

    );

  };



  const renderDestinationsModule = () => {
    const parts = route.split('/');
    if (parts[1] === 'new') {
      return (
        <DestinationEditorPage
          onBack={() => adminNavigate('destinations')}
          onSaved={(msg) => flashAndNavigate('destinations', msg)}
        />
      );
    }
    if (parts[1] === 'edit' && parts[2]) {
      return (
        <DestinationEditorPage
          destinationId={parts[2]}
          onBack={() => adminNavigate('destinations')}
          onSaved={(msg) => flashAndNavigate('destinations', msg)}
          onDeleted={(msg) => flashAndNavigate('destinations', msg)}
        />
      );
    }
    return <DestinationsPage />;
  };

  const renderPage = () => {

    switch (activeNav) {

      case 'dashboard':

        return <DashboardPage />;

      case 'destinations':

        return renderDestinationsModule();

      case 'articles':

        return renderArticlesModule(
          'articles',
          'article',
          t('articles.title'),
          t('articles.description'),
        );

      case 'news':

        return renderArticlesModule(
          'news',
          'news',
          t('articles.newsTitle'),
          t('articles.newsDescription'),
        );

      case 'banners':

        return <BannersPage />;

      case 'featured':

        return <FeaturedPage />;

      case 'gallery':

        return <GalleryPage />;

      case 'review':

        return <ReviewPage />;

      case 'comments':

        return <CommentsPage />;

      case 'users':

        return <UsersPage />;

      case 'activity':

        return <ActivityPage />;

      default:

        return <DashboardPage />;

    }

  };



  return (

    <PermissionsProvider value={permissions}>

    <div className={`admin-shell${sidebarCollapsed ? ' sidebar-collapsed' : ''}${enterShell ? ' shell-enter' : ''}`}>

      <Sidebar

        active={activeNav}

        collapsed={sidebarCollapsed}

        mobileOpen={mobileNavOpen}

        visibleNavIds={visibleNavIds}

        onToggle={() => setSidebarCollapsed((v) => !v)}

        onLogout={() => {

          adminApi.logout();

          setAuth(null);

        }}

        onNavigate={handleNavigate}

        onCloseMobile={() => setMobileNavOpen(false)}

      />

      <div className="admin-main">

        <Header

          auth={auth}

          onMenuToggle={() => setMobileNavOpen((v) => !v)}

          searchQuery={searchQuery}

          onSearchChange={setSearchQuery}

          onSearch={handleSearch}

          inbox={inbox}

          onNavigate={handleNavigate}

          canSeeReview={visibleNavIds.includes('review')}

          visibleNavIds={visibleNavIds}

          onLogout={() => {
            adminApi.logout();
            setAuth(null);
          }}

        />

        {searchResults && (

          <div className="search-dropdown search-enter">

            {searchResults.length === 0 ? (

              <p className="search-empty">{t('common.noResults')}</p>

            ) : (

              searchResults.map((r) => (

                <button

                  key={`${r.entityType}-${r.id}`}

                  type="button"

                  className="search-result-item"

                  onClick={() => handleSearchSelect(r)}

                >

                  {r.imageUrl && <img src={r.imageUrl} alt="" />}

                  <div>

                    <strong>{r.title}</strong>

                    {r.subtitle && <span>{r.subtitle}</span>}

                  </div>

                </button>

              ))

            )}

            <button type="button" className="search-close" onClick={() => setSearchResults(null)}>

              {t('common.close')}

            </button>

          </div>

        )}

        <main className="admin-content">

          <PageTransition pageKey={route}>{renderPage()}</PageTransition>

        </main>

      </div>

    </div>

    </PermissionsProvider>

  );

}


