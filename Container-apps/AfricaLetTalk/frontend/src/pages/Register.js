import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

function Register({ onLogin }) {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    fullName: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [registered, setRegistered] = useState(false);
  const [registeredEmail, setRegisteredEmail] = useState('');
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
    setLoading(true);

    try {
      const response = await fetch('/api/auth/register', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (response.ok) {
        if (data.requiresVerification) {
          setRegistered(true);
          setRegisteredEmail(data.email);
        } else {
          onLogin(data.user, data.token);
          navigate('/feed');
        }
      } else {
        setError(data.error || 'Registration failed');
      }
    } catch (error) {
      console.error('Registration error:', error);
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
        body: JSON.stringify({ email: registeredEmail })
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

  if (registered) {
    return (
      <div className="verify-wrapper">
        <div className="verify-card">
          <div className="verify-icon">📧</div>
          <h2>Check Your Email</h2>
          <p>We've sent a verification link to</p>
          <p className="verify-email">{registeredEmail}</p>
          <p>Click the link in the email to activate your account.</p>
          <button className="verify-btn" onClick={handleResend} disabled={resending}>
            {resending ? 'Sending...' : 'Resend Verification Email'}
          </button>
          {resendMsg && <p style={{ marginTop: '12px', fontSize: '14px' }}>{resendMsg}</p>}
          <p style={{ marginTop: '20px' }}>
            <span className="auth-link">
              Already verified?{' '}
              <span onClick={() => navigate('/login')} style={{ cursor: 'pointer', color: 'var(--primary)', fontWeight: 600 }}>
                Sign in
              </span>
            </span>
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="auth-wrapper">
      <div className="auth-card">
        <div 
          className="auth-image" 
          style={{ backgroundImage: "url('https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=800&q=80')" }}
        ></div>
        <div className="auth-form">
          <h2>Join LetsConnect</h2>
          <p className="auth-subtitle">Create your account and start connecting</p>
          {error && <div className="error">{error}</div>}
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Full Name</label>
              <input
                type="text"
                name="fullName"
                value={formData.fullName}
                onChange={handleChange}
                required
                placeholder="Your full name"
              />
            </div>
            <div className="form-group">
              <label>Username</label>
              <input
                type="text"
                name="username"
                value={formData.username}
                onChange={handleChange}
                required
                placeholder="Choose a username"
              />
            </div>
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
                minLength="6"
                placeholder="Min 6 characters"
              />
            </div>
            <button type="submit" className="btn-primary" disabled={loading}>
              {loading ? 'Creating account...' : 'Create Account'}
            </button>
          </form>
          <p className="auth-link">
            Already have an account?{' '}
            <span onClick={() => navigate('/login')}>Sign in</span>
          </p>
        </div>
      </div>
    </div>
  );
}

export default Register;
