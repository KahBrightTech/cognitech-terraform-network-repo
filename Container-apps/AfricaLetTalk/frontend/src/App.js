import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import Home from './pages/Home';
import Login from './pages/Login';
import Register from './pages/Register';
import VerifyEmail from './pages/VerifyEmail';
import Feed from './pages/Feed';
import Messages from './pages/Messages';
import NotFound from './pages/NotFound';
import Header from './components/Header';

function AppContent({ user, onLogout, onUserUpdate, onLogin }) {
  const location = useLocation();
  const isHomePage = location.pathname === '/' && !user;

  return (
    <div className="App">
      {/* Only show Header when NOT on home page */}
      {!isHomePage && <Header user={user} onLogout={onLogout} onUserUpdate={onUserUpdate} />}
      <Routes>
        <Route path="/" element={user ? <Navigate to="/feed" /> : <Home />} />
        <Route 
          path="/login" 
          element={user ? <Navigate to="/feed" /> : <Login onLogin={onLogin} />} 
        />
        <Route 
          path="/register" 
          element={user ? <Navigate to="/feed" /> : <Register onLogin={onLogin} />} 
        />
        <Route 
          path="/verify-email" 
          element={<VerifyEmail onLogin={onLogin} />} 
        />
        <Route 
          path="/feed" 
          element={user ? <Feed user={user} /> : <Navigate to="/login" />} 
        />
        <Route 
          path="/messages" 
          element={user ? <Messages user={user} /> : <Navigate to="/login" />} 
        />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </div>
  );
}

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      verifyToken(token);
    } else {
      setLoading(false);
    }
  }, []);

  const verifyToken = async (token) => {
    try {
      const response = await fetch('/api/auth/verify', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        setUser(data.user);
      } else {
        localStorage.removeItem('token');
      }
    } catch (error) {
      console.error('Token verification failed:', error);
      localStorage.removeItem('token');
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = (userData, token) => {
    setUser(userData);
    localStorage.setItem('token', token);
  };

  const handleLogout = () => {
    setUser(null);
    localStorage.removeItem('token');
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <Router>
      <AppContent user={user} onLogout={handleLogout} onUserUpdate={setUser} onLogin={handleLogin} />
    </Router>
  );
}

export default App;
