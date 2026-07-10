import { useEffect, useState } from 'react';
import { adminApi, AdminUser, CreateAdminUserPayload } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { EditorModal } from '../components/EditorModal';
import { useI18n } from '../i18n';
import { PlusIcon, UserIcon } from '../components/Icons';

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
  const [editingId, setEditingId] = useState<string | null>(null);
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

  const openCreate = () => {
    setEditingId(null);
    setForm(emptyUser());
    setModalOpen(true);
  };

  const submitSave = async () => {
    setSaving(true);
    try {
      if (editingId) {
        await adminApi.updateAdminUser(editingId, {
          email: form.email,
          fullName: form.fullName,
          password: form.password || undefined,
        });
        setToast(t('users.updated'));
      } else {
        await adminApi.createAdminUser(form);
        setToast(t('users.created'));
      }
      setModalOpen(false);
      setForm(emptyUser());
      setEditingId(null);
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

  const totalCount = users.length;
  const activeCount = users.filter((u) => u.isActive).length;
  const adminCount = users.filter((u) => u.role === 'Admin').length;
  const managerCount = users.filter((u) => u.role === 'TravelManager').length;

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('users.title') }]} />
      <ContentPageHeader title={t('users.title')} description={t('users.description')}>
        <button type="button" className="btn-primary" onClick={openCreate}>
          <PlusIcon size={16} />
          {t('users.create')}
        </button>
      </ContentPageHeader>
      <ContentToast message={toast} />

      <div className="dashboard-stats-grid" style={{ marginBottom: 20, display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16 }}>
        <div className="stat-card" style={{ display: 'flex', alignItems: 'center', gap: 16, padding: 16, background: 'var(--card-bg)', borderRadius: 12, border: '1px solid var(--border)' }}>
          <div className="stat-icon-wrap" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: 44, height: 44, borderRadius: 10, background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6' }}>
            <UserIcon size={24} />
          </div>
          <div>
            <p className="stat-label" style={{ fontSize: 13, color: 'var(--muted)', margin: 0 }}>Tổng số tài khoản</p>
            <p className="stat-value" style={{ fontSize: 22, fontWeight: 700, margin: 0 }}>{totalCount}</p>
          </div>
        </div>

        <div className="stat-card" style={{ display: 'flex', alignItems: 'center', gap: 16, padding: 16, background: 'var(--card-bg)', borderRadius: 12, border: '1px solid var(--border)' }}>
          <div className="stat-icon-wrap" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: 44, height: 44, borderRadius: 10, background: 'rgba(16, 185, 129, 0.1)', color: '#10b981' }}>
            <UserIcon size={24} />
          </div>
          <div>
            <p className="stat-label" style={{ fontSize: 13, color: 'var(--muted)', margin: 0 }}>Đang hoạt động</p>
            <p className="stat-value" style={{ fontSize: 22, fontWeight: 700, margin: 0 }}>{activeCount}</p>
          </div>
        </div>

        <div className="stat-card" style={{ display: 'flex', alignItems: 'center', gap: 16, padding: 16, background: 'var(--card-bg)', borderRadius: 12, border: '1px solid var(--border)' }}>
          <div className="stat-icon-wrap" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: 44, height: 44, borderRadius: 10, background: 'rgba(139, 92, 246, 0.1)', color: '#8b5cf6' }}>
            <UserIcon size={24} />
          </div>
          <div>
            <p className="stat-label" style={{ fontSize: 13, color: 'var(--muted)', margin: 0 }}>Quản trị viên (Admin)</p>
            <p className="stat-value" style={{ fontSize: 22, fontWeight: 700, margin: 0 }}>{adminCount}</p>
          </div>
        </div>

        <div className="stat-card" style={{ display: 'flex', alignItems: 'center', gap: 16, padding: 16, background: 'var(--card-bg)', borderRadius: 12, border: '1px solid var(--border)' }}>
          <div className="stat-icon-wrap" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: 44, height: 44, borderRadius: 10, background: 'rgba(245, 158, 11, 0.1)', color: '#f59e0b' }}>
            <UserIcon size={24} />
          </div>
          <div>
            <p className="stat-label" style={{ fontSize: 13, color: 'var(--muted)', margin: 0 }}>Content Manager</p>
            <p className="stat-value" style={{ fontSize: 22, fontWeight: 700, margin: 0 }}>{managerCount}</p>
          </div>
        </div>
      </div>

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
                      style={{ marginRight: 8 }}
                      onClick={() => {
                        setEditingId(u.id);
                        setForm({
                          username: u.username,
                          email: u.email,
                          fullName: u.fullName,
                          password: '',
                          role: u.role,
                        });
                        setModalOpen(true);
                      }}
                    >
                      {t('common.edit')}
                    </button>
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
        title={editingId ? t('common.edit') : t('users.createTitle')}
        onClose={() => setModalOpen(false)}
        onSave={submitSave}
        saving={saving}
      >
        <label className="editor-field">
          <span className="field-label">{t('users.username')} *</span>
          <input
            value={form.username}
            onChange={(e) => setForm((f) => ({ ...f, username: e.target.value }))}
            required
            disabled={!!editingId}
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
          <span className="field-label">{t('login.password')}{!editingId && ' *'}</span>
          <input
            type="password"
            value={form.password}
            onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
            required={!editingId}
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
