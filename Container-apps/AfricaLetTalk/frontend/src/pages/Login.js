import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

function Login({ onLogin }) {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [needsVerification, setNeedsVerification] = useState(false);
  const [resending, setResending] = useState(false);
  const [resendMsg, setResendMsg] = useState('');

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setNeedsVerification(false);
    setResendMsg('');
    setLoading(true);

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (response.ok) {
        onLogin(data.user, data.token);
        navigate('/feed');
      } else if (data.requiresVerification) {
        setNeedsVerification(true);
      } else {
        setError(data.error || 'Login failed');
      }
    } catch (error) {
      console.error('Login error:', error);
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setResending(true);
    setResendMsg('');
    try {
      const resp = await fetch('/api/auth/resend-verification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: formData.email })
      });
      const data = await resp.json();
      if (resp.ok) {
        setResendMsg('Verification email sent! Check your inbox.');
      } else {
        setResendMsg(data.error || 'Failed to resend');
      }
    } catch (err) {
      setResendMsg('Network error. Please try again.');
    } finally {
      setResending(false);
    }
  };

  return (
    <div className="auth-wrapper">
      <div className="auth-card">
        <div 
          className="auth-image" 
          style={{ backgroundImage: "url('https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=800&q=80')" }}
        ></div>
        <div className="auth-form">
          <h2>Welcome back</h2>
          <p className="auth-subtitle">Sign in to continue to LetsConnect</p>
          {error && <div className="error">{error}</div>}
          {needsVerification && (
            <div className="error" style={{ background: '#fff3cd', color: '#856404', borderColor: '#ffc107' }}>
              <p style={{ margin: '0 0 8px' }}>Your email is not verified yet. Please check your inbox.</p>
              <button
                className="verify-btn"
                onClick={handleResend}
                disabled={resending}
                style={{ fontSize: '13px', padding: '6px 14px' }}
              >
                {resending ? 'Sending...' : 'Resend Verification Email'}
              </button>
              {resendMsg && <p style={{ margin: '6px 0 0', fontSize: '13px' }}>{resendMsg}</p>}
            </div>
          )}
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Email</label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                required
                placeholder="you@example.com"
              />
            </div>
            <div className="form-group">
              <label>Password</label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                required
                placeholder="Enter your password"
              />
            </div>
            <button type="submit" className="btn-primary" disabled={loading}>
              {loading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
          <p className="auth-link">
            Don't have an account?{' '}
            <span onClick={() => navigate('/register')}>Create one</span>
          </p>
        </div>
      </div>
    </div>
  );
}

export default Login;
