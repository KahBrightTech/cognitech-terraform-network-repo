import React from 'react';
import { useNavigate } from 'react-router-dom';

function Home() {
  const navigate = useNavigate();

  return (
    <div className="home-dark-wrapper">
      <div className="home-dark-content">
        {/* Logo Section */}
        <div className="home-logo-container">
          <div className="home-logo">
            <img src="/cognitech-logo.svg" alt="Cognitech" />
          </div>
          <h1 className="home-title">AfricaLetTalk</h1>
          <p className="home-subtitle">Connect. Share. Celebrate Africa.</p>
        </div>

        {/* Sign In Options */}
        <div className="home-auth-buttons">
          <button 
            className="home-btn home-btn-signin" 
            onClick={() => navigate('/login')}
          >
            Sign In
          </button>
          <button 
            className="home-btn home-btn-register" 
            onClick={() => navigate('/register')}
          >
            Create Account
          </button>
        </div>

        {/* Footer */}
        <div className="home-footer">
          <p className="home-powered-by">powered by cognitech</p>
        </div>
      </div>
    </div>
  );
}

export default Home;
