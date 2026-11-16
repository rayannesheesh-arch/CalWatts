import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { useAuth } from '../context/AuthContext.jsx';
import CalWattBrand from './CalWattBrand.jsx';

const userLinks = [
  ['/dashboard', 'Overview', '⌂'],
  ['/appliances', 'Appliances', '▦'],
  ['/calculator', 'Calculator', 'ϟ'],
  ['/history', 'Consumption history', '◷'],
  ['/simulation', 'Simulation', '▤'],
  ['/analytics', 'Analytics', '▥'],
  ['/settings', 'Settings', '⚙'],
];
const adminLinks = [
  ['/admin', 'Overview', '⌂'],
  ['/admin/users', 'User management', '♙'],
  ['/admin/monitoring', 'Energy monitoring', 'ϟ'],
  ['/admin/reports', 'Reports', '▥'],
  ['/admin/rates', 'Electricity rates', '₱'],
  ['/admin/audit', 'Audit logs', '◷'],
];

export default function AppShell() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);
  const links = user.role === 'admin' ? adminLinks : userLinks;
  const mobileLinks = [
    ['/dashboard', 'Dashboard', '⌂'],
    ['/appliances', 'Appliances', '▦'],
    ['/simulation', 'Simulate', '▤'],
    ['/analytics', 'Analytics', '▥'],
    ['/settings', 'Settings', '⚙'],
  ];

  const signOut = async () => {
    try {
      await logout();
      navigate('/login');
    } catch (error) {
      window.alert(error.response?.data?.error ?? 'Unable to sign out right now.');
    }
  };

  return <div className="app-shell">
    <aside className={`sidebar ${menuOpen ? 'sidebar-open' : ''}`}>
      <NavLink className="brand" to={user.role === 'admin' ? '/admin' : '/dashboard'} onClick={() => setMenuOpen(false)}>
        <CalWattBrand subtitle={user.role === 'admin' ? 'ADMIN CONSOLE' : 'ENERGY ESTIMATES'} />
      </NavLink>
      <div className="sidebar-section">WORKSPACE</div>
      <nav className="side-nav" aria-label="Main navigation">
        {links.map(([to, label, icon]) => <NavLink key={to} to={to} end={to === '/admin'} onClick={() => setMenuOpen(false)}>
          <span className="nav-icon">{icon}</span>{label}
        </NavLink>)}
      </nav>
      <div className="sidebar-bottom">
        <div className="profile-chip"><span className="avatar">{(user.fullName || 'C').slice(0, 1).toUpperCase()}</span><div><strong>{user.fullName}</strong><small>{user.role === 'admin' ? 'Administrator' : 'Household user'}</small></div></div>
        <button className="signout-button" onClick={signOut}>↗ <span>Sign out</span></button>
      </div>
    </aside>
    {menuOpen && <button aria-label="Close navigation" className="mobile-backdrop" onClick={() => setMenuOpen(false)} />}
    <main className="main-area">
      <header className="topbar"><button className="menu-toggle" onClick={() => setMenuOpen((open) => !open)} aria-label={menuOpen ? 'Close navigation' : 'Open navigation'} aria-expanded={menuOpen}>☰</button><div className="breadcrumb"><span className="breadcrumb-brand">CALWATT</span><span className="breadcrumb-divider">/</span><span>{user.role === 'admin' ? 'Administration' : 'My household'}</span></div><div className="topbar-user"><span>{user.fullName}</span><span className="avatar">{(user.fullName || 'C').slice(0, 1).toUpperCase()}</span></div></header>
      <div className="content"><Outlet /></div>
      <footer className="app-footer">CalWatt estimates use appliance specifications and configured hours; they are not meter readings.</footer>
    </main>
    {user.role === 'user' && <nav className="mobile-nav" aria-label="Primary navigation">
      {mobileLinks.map(([to, label, icon]) => <NavLink key={to} to={to} aria-label={label} title={label}>
        <span className="mobile-nav-icon" aria-hidden="true">{icon}</span><span>{label}</span>
      </NavLink>)}
    </nav>}
  </div>;
}
