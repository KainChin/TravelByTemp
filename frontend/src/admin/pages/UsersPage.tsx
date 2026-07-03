import { useEffect, useState } from 'react';
import { adminApi, AdminUser, CreateAdminUserPayload } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { EditorModal } from '../components/EditorModal';
import { useI18n } from '../i18n';
import { PlusIcon } from '../components/Icons';

const emptyUser = (): CreateAdminUserPayload => ({
  username: '',
  email: '',
  password: '',
  fullName: '',
  role: 'TravelManager',
});

const ROLES = ['TravelManager', 'Admin'] as const;

export function UsersPage() {
  const { t, formatTimeAgo } = useI18n();
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState<CreateAdminUserPayload>(emptyUser);
  const [saving, setSaving] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    adminApi
      .adminUsers()
      .then(setUsers)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const submitCreate = async () => {
    setSaving(true);
    try {
      await adminApi.createAdminUser(form);
      setToast(t('users.created'));
      setModalOpen(false);
      setForm(emptyUser());
      load();
    } catch (err) {
      setToast(err instanceof Error ? err.message : t('common.saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  const toggleActive = async (user: AdminUser) => {
    setBusyId(user.id);
    try {
      await adminApi.toggleUserActive(user.id);
      setToast(t('users.updated'));
      load();
    } catch (e) {
      setToast(e instanceof Error ? e.message : t('common.actionFailed'));
    } finally {
      setBusyId(null);
    }
  };

  const changeRole = async (user: AdminUser, role: string) => {
    if (user.role === role) return;
    setBusyId(user.id);
    try {
      await adminApi.updateUserRole(user.id, role);
      setToast(t('users.updated'));
      load();
    } catch (e) {
      setToast(e instanceof Error ? e.message : t('common.actionFailed'));
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('users.title') }]} />
      <ContentPageHeader title={t('users.title')} description={t('users.description')}>
        <button type="button" className="btn-primary" onClick={() => setModalOpen(true)}>
          <PlusIcon size={16} />
          {t('users.create')}
        </button>
      </ContentPageHeader>
      <ContentToast message={toast} />

      {error && <p className="content-error">{error}</p>}

      <div className="content-card">
        {loading ? (
          <p className="content-muted">{t('common.loading')}…</p>
        ) : (
          <table className="content-table">
            <thead>
              <tr>
                <th scope="col">{t('users.username')}</th>
                <th scope="col">{t('users.fullName')}</th>
                <th scope="col">{t('users.email')}</th>
                <th scope="col">{t('users.role')}</th>
                <th scope="col">{t('table.status')}</th>
                <th scope="col">{t('users.createdAt')}</th>
                <th scope="col">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id}>
                  <td>{u.username}</td>
                  <td>{u.fullName}</td>
                  <td>{u.email}</td>
                  <td>
                    <select
                      className="editor-select editor-select-sm"
                      value={u.role}
                      disabled={busyId === u.id}
                      onChange={(e) => changeRole(u, e.target.value)}
                    >
                      {ROLES.map((r) => (
                        <option key={r} value={r}>
                          {r === 'Admin' ? t('roles.admin') : t('roles.contentManager')}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td>
                    <span className={`status-pill${u.isActive ? ' published' : ' draft'}`}>
                      {u.isActive ? t('common.active') : t('common.inactive')}
                    </span>
                  </td>
                  <td>{formatTimeAgo(u.createdAt)}</td>
                  <td>
                    <button
                      type="button"
                      className="btn-ghost btn-sm"
                      disabled={busyId === u.id}
                      onClick={() => toggleActive(u)}
                    >
                      {u.isActive ? t('users.deactivate') : t('users.activate')}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <EditorModal
        open={modalOpen}
        title={t('users.createTitle')}
        onClose={() => setModalOpen(false)}
        onSave={submitCreate}
        saving={saving}
      >
        <label className="editor-field">
          <span className="field-label">{t('users.username')} *</span>
          <input
            value={form.username}
            onChange={(e) => setForm((f) => ({ ...f, username: e.target.value }))}
            required
          />
        </label>
        <label className="editor-field">
          <span className="field-label">{t('users.fullName')} *</span>
          <input
            value={form.fullName}
            onChange={(e) => setForm((f) => ({ ...f, fullName: e.target.value }))}
            required
          />
        </label>
        <label className="editor-field">
          <span className="field-label">{t('users.email')} *</span>
          <input
            type="email"
            value={form.email}
            onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
            required
          />
        </label>
        <label className="editor-field">
          <span className="field-label">{t('login.password')} *</span>
          <input
            type="password"
            value={form.password}
            onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
            required
            minLength={8}
          />
        </label>
        <label className="editor-field">
          <span className="field-label">{t('users.role')}</span>
          <select
            className="editor-select"
            value={form.role}
            onChange={(e) => setForm((f) => ({ ...f, role: e.target.value }))}
          >
            {ROLES.map((r) => (
              <option key={r} value={r}>
                {r === 'Admin' ? t('roles.admin') : t('roles.contentManager')}
              </option>
            ))}
          </select>
        </label>
      </EditorModal>
    </div>
  );
}
