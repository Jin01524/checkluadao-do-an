import { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem('adminToken'));
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('adminUser');
    try {
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const isAdmin = user?.role === 'admin';
  const isModerator = user?.role === 'moderator';
  const isLoggedIn = !!token;

  const login = (newToken, userData) => {
    localStorage.setItem('adminToken', newToken);
    if (userData) {
      localStorage.setItem('adminUser', JSON.stringify(userData));
      setUser(userData);
    }
    setToken(newToken);
  };

  const logout = () => {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ isAdmin, isModerator, isLoggedIn, user, token, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
