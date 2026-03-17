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
            <img src="/cognitech-logo.svg" alt="LetsConnect" />
          </div>
          <h1 className="home-title">LetsConnect</h1>
          <p className="home-tagline">
            <span className="tagline-connect">Connect</span>
            <span className="tagline-share">Share</span>
            <span className="tagline-celebrate">Celebrate</span>
            <span className="tagline-relationships">Relationships</span>
          </p>
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
