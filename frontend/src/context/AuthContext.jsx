import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { api, errorMessage, mutate } from '../services/api.js';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const refresh = useCallback(async () => {
    setError('');
    try {
      const { data } = await api.get('/auth/me');
      setUser(data.user);
    } catch (requestError) {
      if (requestError.response?.status === 401) setUser(null);
      else setError(errorMessage(requestError));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { refresh(); }, [refresh]);

  const login = async (credentials) => {
    const { data } = await mutate('post', '/auth/login', credentials);
    setUser(data.user);
    return data.user;
  };
  const register = async (values) => {
    const { data } = await mutate('post', '/auth/register', values);
    setUser(data.user);
    return data.user;
  };
  const logout = async () => {
    await mutate('post', '/auth/logout');
    setUser(null);
  };

  const value = useMemo(() => ({ user, loading, error, login, register, logout, refresh }), [user, loading, error, refresh]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider.');
  return context;
}
