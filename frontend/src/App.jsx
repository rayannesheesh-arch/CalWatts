import { lazy, Suspense } from 'react';
import { Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';
import { useAuth } from './context/AuthContext.jsx';
import AppShell from './components/AppShell.jsx';
import { ErrorNotice, Loading } from './components/Ui.jsx';

const AuthPage = lazy(() => import('./pages/AuthPage.jsx'));
const DashboardPage = lazy(() => import('./pages/DashboardPage.jsx'));
const AppliancesPage = lazy(() => import('./pages/AppliancesPage.jsx'));
const CalculatorPage = lazy(() => import('./pages/CalculatorPage.jsx'));
const HistoryPage = lazy(() => import('./pages/HistoryPage.jsx'));
const SimulationPage = lazy(() => import('./pages/SimulationPage.jsx'));
const AnalyticsPage = lazy(() => import('./pages/AnalyticsPage.jsx'));
const SettingsPage = lazy(() => import('./pages/SettingsPage.jsx'));
const AdminDashboardPage = lazy(() => import('./pages/admin/AdminDashboardPage.jsx'));
const AdminUsersPage = lazy(() => import('./pages/admin/AdminUsersPage.jsx'));
const AdminMonitoringPage = lazy(() => import('./pages/admin/AdminMonitoringPage.jsx'));
const AdminReportsPage = lazy(() => import('./pages/admin/AdminReportsPage.jsx'));
const AdminRatesPage = lazy(() => import('./pages/admin/AdminRatesPage.jsx'));
const AdminAuditPage = lazy(() => import('./pages/admin/AdminAuditPage.jsx'));

function Protected({ role }) {
  const { user, loading } = useAuth();
  const location = useLocation();
  if (loading) return <Loading label="Checking your session…" />;
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  if (role && user.role !== role) return <Navigate to={user.role === 'admin' ? '/admin' : '/dashboard'} replace />;
  return <Outlet />;
}

function HomeRedirect() {
  const { user } = useAuth();
  return <Navigate to={user?.role === 'admin' ? '/admin' : '/dashboard'} replace />;
}

export default function App() {
  const { error } = useAuth();
  return <>
    {error && <div className="startup-error"><ErrorNotice message={`API connection: ${error}`} /></div>}
    <Suspense fallback={<Loading label="Loading CalWatt…" />}>
    <Routes>
      <Route path="/login" element={<AuthPage />} />
      <Route path="/register" element={<AuthPage register />} />
      <Route element={<Protected />}>
        <Route element={<AppShell />}>
          <Route path="/" element={<HomeRedirect />} />
          <Route element={<Protected role="user" />}>
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/appliances" element={<AppliancesPage />} />
            <Route path="/calculator" element={<CalculatorPage />} />
            <Route path="/history" element={<HistoryPage />} />
            <Route path="/simulation" element={<SimulationPage />} />
            <Route path="/analytics" element={<AnalyticsPage />} />
            <Route path="/settings" element={<SettingsPage />} />
          </Route>
          <Route element={<Protected role="admin" />}>
            <Route path="/admin" element={<AdminDashboardPage />} />
            <Route path="/admin/users" element={<AdminUsersPage />} />
            <Route path="/admin/monitoring" element={<AdminMonitoringPage />} />
            <Route path="/admin/reports" element={<AdminReportsPage />} />
            <Route path="/admin/rates" element={<AdminRatesPage />} />
            <Route path="/admin/audit" element={<AdminAuditPage />} />
          </Route>
        </Route>
      </Route>
      <Route path="*" element={<HomeRedirect />} />
    </Routes>
    </Suspense>
  </>;
}
