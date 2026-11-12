import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import logoImg from '../assets/Logo-checkluadao.png';

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const { isAdmin, isModerator, isLoggedIn, user, logout } = useAuth();
  const location = useLocation();

  const isActive = (path) => location.pathname === path;
  const close = () => setOpen(false);

  return (
    <header className="sticky top-0 w-full z-50 bg-white/90 backdrop-blur-md border-b border-white/10 shadow-sm">
      <div className="h-14 max-w-[1280px] mx-auto px-4 sm:px-6 flex items-center justify-between gap-4">
        {/* Left: Brand */}
        <div className="flex items-center gap-6">
          <Link to="/" reloadDocument className="flex items-center gap-2 focus:outline-none group" onClick={close}>
            <img
              src={logoImg}
              alt="CheckLuaDao Logo"
              className="h-7 w-auto object-contain transition-transform group-hover:scale-105"
            />
            <div className="flex flex-col">
              <div className="flex items-center gap-1.5">
                <span className="text-sm sm:text-base font-bold tracking-tight text-on-surface">
                  Check<span className="text-primary">LuaDao</span>
                </span>
                <span className="font-label-badge text-[9px] uppercase px-1 py-0.2 rounded-none bg-surface-container text-tertiary border border-tertiary/20">
                  AI v4.1
                </span>
              </div>
              <span className="text-[9px] text-on-surface-variant hidden sm:inline -mt-0.5">
                Lá chắn phát hiện tin nhắn lừa đảo quốc gia
              </span>
            </div>
          </Link>

          {/* Nav Links */}
          <nav className="hidden lg:flex items-center gap-1">
            <Link
              to="/"
              reloadDocument
              className={`px-3 py-1.5 text-xs font-medium flex items-center gap-1.5 rounded-none transition-all ${
                isActive('/')
                  ? 'bg-primary-container text-on-primary-container shadow-sm font-semibold'
                  : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'
              }`}
            >
              <span className="material-symbols-outlined text-[15px]">radar</span>
              <span>Kiểm tra tin nhắn</span>
            </Link>

            <Link
              to="/templates"
              reloadDocument
              className={`px-3 py-1.5 text-xs font-medium flex items-center gap-1.5 rounded-none transition-all ${
                isActive('/templates')
                  ? 'bg-primary-container text-on-primary-container shadow-sm font-semibold'
                  : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'
              }`}
            >
              <span className="material-symbols-outlined text-[15px]">database</span>
              <span>Kho mẫu lừa đảo</span>
            </Link>

            {isLoggedIn && (isAdmin || isModerator) && (
              <Link
                to="/admin/dashboard"
                reloadDocument
                className={`px-3 py-1.5 text-xs font-medium flex items-center gap-1.5 rounded-none transition-all ${
                  isActive('/admin/dashboard')
                    ? 'bg-primary-container text-on-primary-container shadow-sm font-semibold'
                    : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'
                }`}
              >
                <span className="material-symbols-outlined text-[15px]">tune</span>
                <span>{isAdmin ? 'Quản trị hệ thống' : 'Kiểm duyệt tin'}</span>
              </Link>
            )}
          </nav>
        </div>

        {/* Right Action Suite */}
        <div className="flex items-center gap-2 sm:gap-3">
          {/* AI Online Widget */}
          <div className="hidden md:flex items-center gap-1.5 px-2 py-0.5 bg-surface-container-low/80 border border-white/5 rounded-none">
            <span className="relative flex h-1.5 w-1.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-none bg-[#10b981] opacity-75"></span>
              <span className="relative inline-flex rounded-none h-1.5 w-1.5 bg-[#10b981]"></span>
            </span>
            <span className="font-label-badge text-[9px] text-tertiary tracking-wide uppercase font-semibold">
              AI Online 24/7
            </span>
          </div>

          <a
            href="https://github.com/Jin01524/checkluadao-do-an/releases/download/v1.2.11/CheckLuaDao-v1.2.11-build17-android.apk"
            className="inline-flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-none border border-primary bg-primary px-2.5 py-1 text-xs font-semibold text-on-primary transition-colors hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            aria-label="Tải app Android"
            title="Tải app Android"
          >
            <span className="material-symbols-outlined text-[15px]" aria-hidden="true">download</span>
            <span className="hidden sm:inline">Tải app Android</span>
          </a>

          {/* User Auth Info / Actions */}
          {isLoggedIn ? (
            <div className="flex items-center gap-2 pl-2 pr-1.5 py-1 bg-surface-container-low/80 border border-white/5 rounded-none">
              <div className="w-6 h-6 rounded-none bg-primary-container/40 border border-primary/40 flex items-center justify-center text-primary font-bold text-[10px] uppercase">
                {user?.username ? user.username[0] : (isAdmin ? 'A' : 'M')}
              </div>
              <div className="hidden lg:flex flex-col text-left">
                <span className="text-[10px] text-on-surface font-semibold leading-tight truncate max-w-[90px]">
                  {user?.username || (isAdmin ? 'Admin' : 'Kiểm duyệt')}
                </span>
                <span className="text-[8px] text-primary uppercase leading-tight">
                  {isAdmin ? 'Quản trị viên' : 'Kiểm duyệt viên'}
                </span>
              </div>
              <button
                onClick={() => {
                  logout();
                  window.location.href = '/';
                }}
                className="text-on-surface-variant hover:text-error p-1 rounded-none transition-colors text-xs ml-1 flex items-center gap-1"
                title="Đăng xuất"
              >
                <span className="material-symbols-outlined text-[16px]">logout</span>
              </button>
            </div>
          ) : (
            <Link
              to="/admin/login"
              reloadDocument
              className="px-2.5 py-1 text-xs font-medium rounded-none bg-surface-container-high hover:bg-surface-container-highest text-on-surface transition-colors flex items-center gap-1.5 border border-white/10"
            >
              <span className="material-symbols-outlined text-[15px] text-primary">lock</span>
              <span>Đăng nhập</span>
            </Link>
          )}

          {/* Mobile Menu Toggle Button */}
          <button
            onClick={() => setOpen(!open)}
            className="lg:hidden p-1.5 rounded-none bg-surface-container text-on-surface hover:bg-surface-container-high transition-colors"
            aria-label="Toggle menu"
          >
            <span className="material-symbols-outlined text-[18px]">
              {open ? 'close' : 'menu'}
            </span>
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {open && (
        <div className="lg:hidden border-t border-white/10 bg-white px-4 py-2 space-y-1 animate-fadeIn">
          <Link
            to="/"
            reloadDocument
            onClick={close}
            className={`px-3 py-2 text-xs rounded-none flex items-center gap-2 ${
              isActive('/') ? 'bg-primary-container text-on-primary-container font-semibold' : 'text-on-surface-variant'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">radar</span>
            <span>Kiểm tra tin nhắn</span>
          </Link>
          <Link
            to="/templates"
            reloadDocument
            onClick={close}
            className={`px-3 py-2 text-xs rounded-none flex items-center gap-2 ${
              isActive('/templates') ? 'bg-primary-container text-on-primary-container font-semibold' : 'text-on-surface-variant'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">database</span>
            <span>Kho mẫu lừa đảo</span>
          </Link>
          {isLoggedIn && (isAdmin || isModerator) && (
            <Link
              to="/admin/dashboard"
              reloadDocument
              onClick={close}
              className={`px-3 py-2 text-xs rounded-none flex items-center gap-2 ${
                isActive('/admin/dashboard') ? 'bg-primary-container text-on-primary-container font-semibold' : 'text-on-surface-variant'
              }`}
            >
              <span className="material-symbols-outlined text-[16px]">tune</span>
              <span>{isAdmin ? 'Quản trị hệ thống' : 'Kiểm duyệt tin'}</span>
            </Link>
          )}
        </div>
      )}
    </header>
  );
}
