import { useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { ErrorNotice, Field, Loading } from '../components/Ui.jsx';
import { errorMessage } from '../services/api.js';
import CalWattBrand from '../components/CalWattBrand.jsx';

export default function AuthPage({ register = false }) {
  const { user, loading, login, register: createAccount } = useAuth();
  const [values, setValues] = useState({ fullName: '', email: '', password: '' });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  if (loading) return <Loading label="Loading CalWatt…" />;
  if (user) return <Navigate to={user.role === 'admin' ? '/admin' : '/dashboard'} replace />;

  const update = (key) => (event) => setValues((current) => ({ ...current, [key]: event.target.value }));
  const submit = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    try {
      const signedIn = register ? await createAccount(values) : await login(values);
      navigate(location.state?.from ?? (signedIn.role === 'admin' ? '/admin' : '/dashboard'), { replace: true });
    } catch (requestError) {
      setError(errorMessage(requestError));
    } finally {
      setBusy(false);
    }
  };

  return <main className="auth-page">
    <div className="auth-card">
      <Link to="/" className="brand auth-brand"><CalWattBrand subtitle="ENERGY ESTIMATES" /></Link>
      <p className="eyebrow">{register ? 'CREATE YOUR ACCOUNT' : 'WELCOME BACK'}</p>
      <h1>{register ? 'Start with a clearer picture.' : 'Your energy, made visible.'}</h1>
      <p className="muted">{register ? 'Create a personal CalWatt account to manage appliances and estimated usage.' : 'Sign in to continue to your CalWatt workspace.'}</p>
      <ErrorNotice message={error} />
      <form className="form-stack" onSubmit={submit}>
        {register && <Field label="Full name" autoComplete="name" required maxLength={120} value={values.fullName} onChange={update('fullName')} />}
        <Field label="Email address" type="email" autoComplete="email" required value={values.email} onChange={update('email')} />
        <Field label="Password" type="password" autoComplete={register ? 'new-password' : 'current-password'} minLength={10} required value={values.password} onChange={update('password')} />
        {register && <small className="field-hint">Use at least 10 characters. New accounts are regular users.</small>}
        <button className="button primary full-width" disabled={busy}>{busy ? 'Please wait…' : register ? 'Create account' : 'Sign in'}</button>
      </form>
      <p className="auth-switch">{register ? 'Already have an account?' : 'New to CalWatt?'} <Link to={register ? '/login' : '/register'}>{register ? 'Sign in' : 'Create an account'}</Link></p>
      <p className="fine-print">CalWatt estimates energy from appliance ratings and usage hours; it does not read a physical meter.</p>
    </div>
  </main>;
}
