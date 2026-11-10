import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import API from '../api/api';

export default function AdminLoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!username.trim() || !password.trim()) {
      setError('Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.');
      return;
    }

    setLoading(true);
    try {
      const res = await API.post('/api/auth/login', { username, password });
      const token = res.data?.token || res.data?.accessToken;
      const user = res.data?.user;

      if (!token) throw new Error('Không nhận được mã phiên xác thực.');
      login(token, user);

      navigate('/admin/dashboard', { replace: true });
    } catch (err) {
      const serverMessage = err.response?.data?.error || err.response?.data?.message;
      setError(serverMessage || (err.response?.status === 401
        ? 'Tên đăng nhập hoặc mật khẩu quản trị không chính xác.'
        : 'Không thể kết nối máy chủ đăng nhập. Vui lòng thử lại.'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="w-full min-h-[calc(100vh-64px)] flex items-center justify-center py-12 px-4 bg-surface relative overflow-hidden">
      {/* Background Cyber Orbs */}
      <div className="absolute -top-32 left-1/2 -translate-x-1/2 w-[600px] h-[350px] bg-primary-container/15 blur-3xl pointer-events-none rounded-full"></div>

      <div className="w-full max-w-md bg-surface-container-low rounded-2xl p-6 sm:p-8 border border-white/10 shadow-2xl relative z-10">
        {/* Header */}
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-12 h-12 rounded-xl bg-primary-container/20 border border-primary/30 flex items-center justify-center text-primary mb-3">
            <span className="material-symbols-outlined text-[28px]">admin_panel_settings</span>
          </div>
          <span className="font-label-badge text-xs text-primary uppercase mb-1">
            CheckLuaDao Console
          </span>
          <h1 className="font-headline-sm text-2xl font-bold text-on-surface">
            Đăng Nhập Quản Trị
          </h1>
          <p className="font-body-sm text-on-surface-variant mt-1">
            Xác thực phiên điều hành hệ thống phân tích lừa đảo
          </p>
        </div>

        {/* Error */}
        {error && (
          <div role="alert" className="flex items-center gap-2 p-3 bg-error-container/20 border border-error/30 rounded-xl text-error text-body-sm mb-4">
            <span className="material-symbols-outlined text-[18px]">warning</span>
            <span>{error}</span>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-title-md font-medium text-on-surface mb-1.5" htmlFor="username">
              Tên tài khoản quản trị
            </label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[18px]">
                person
              </span>
              <input
                id="username"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Nhập username..."
                className="w-full bg-surface-container text-on-surface text-body-sm pl-10 pr-3 py-2.5 rounded-xl border border-white/10 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                disabled={loading}
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-title-md font-medium text-on-surface mb-1.5" htmlFor="password">
              Mật khẩu bảo mật
            </label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[18px]">
                lock
              </span>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-surface-container text-on-surface text-body-sm pl-10 pr-3 py-2.5 rounded-xl border border-white/10 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                disabled={loading}
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2.5 px-4 bg-primary-container hover:bg-inverse-primary text-on-primary-container font-title-md text-sm font-bold rounded-xl shadow-md transition-all flex items-center justify-center gap-2 mt-2 disabled:opacity-50"
          >
            {loading ? (
              <>
                <span className="w-4 h-4 rounded-full border-2 border-white/20 border-t-white animate-spin"></span>
                <span>Đang xác thực...</span>
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-[18px]">vpn_key</span>
                <span>Đăng Nhập Điều Hành</span>
              </>
            )}
          </button>
        </form>

        <div className="mt-6 text-center text-xs text-on-surface-variant">
          <Link to="/" className="hover:text-primary transition-colors inline-flex items-center gap-1">
            <span className="material-symbols-outlined text-[14px]">arrow_back</span>
            <span>Trở về trang chủ</span>
          </Link>
        </div>
      </div>
    </main>
  );
}
