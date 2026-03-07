import React, { useEffect, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';

function VerifyEmail({ onLogin }) {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [status, setStatus] = useState('verifying'); // verifying | success | error
  const [message, setMessage] = useState('');

  useEffect(() => {
    const token = searchParams.get('token');
    if (!token) {
      setStatus('error');
      setMessage('Invalid verification link. No token provided.');
      return;
    }

    const verify = async () => {
      try {
        const response = await fetch(`/api/auth/verify-email?token=${encodeURIComponent(token)}`);
        const data = await response.json();

        if (response.ok) {
          setStatus('success');
          setMessage('Your email has been verified!');
          if (data.token && data.user) {
            setTimeout(() => {
              onLogin(data.user, data.token);
              navigate('/feed');
            }, 2000);
          }
        } else {
          setStatus('error');
          setMessage(data.error || 'Verification failed. The link may have expired.');
        }
      } catch (err) {
        setStatus('error');
        setMessage('Network error. Please try again.');
      }
    };

    verify();
  }, [searchParams, onLogin, navigate]);

  return (
    <div className="verify-wrapper">
      <div className="verify-card">
        {status === 'verifying' && (
          <>
            <div className="verify-icon">⏳</div>
            <h2>Verifying your email...</h2>
            <p>Please wait while we confirm your account.</p>
          </>
        )}
        {status === 'success' && (
          <>
            <div className="verify-icon verify-success">✅</div>
            <h2>Email Verified!</h2>
            <p>{message}</p>
            <p style={{ marginTop: '12px', color: '#666' }}>Redirecting to your feed...</p>
          </>
        )}
        {status === 'error' && (
          <>
            <div className="verify-icon verify-error">❌</div>
            <h2>Verification Failed</h2>
            <p>{message}</p>
            <button className="verify-btn" onClick={() => navigate('/login')} style={{ marginTop: '16px' }}>
              Go to Login
            </button>
          </>
        )}
      </div>
    </div>
  );
}

export default VerifyEmail;
