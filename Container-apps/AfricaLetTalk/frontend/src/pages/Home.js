import React from 'react';
import { useNavigate } from 'react-router-dom';

function Home() {
  const navigate = useNavigate();

  return (
    <div>
      <div className="container">
        {/* Hero Section */}
        <div className="hero">
          <div className="hero-bg"></div>
          <div className="hero-content">
            <h2>Connect. Share. Celebrate Africa.</h2>
            <p>
              Join a vibrant community where African voices come together. 
              Share stories, build friendships, and celebrate our rich heritage.
            </p>
            <div className="hero-buttons">
              <button className="btn-hero btn-hero-primary" onClick={() => navigate('/register')}>
                Join the Community
              </button>
              <button className="btn-hero btn-hero-outline" onClick={() => navigate('/login')}>
                Sign In
              </button>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="stats-bar">
          <div className="stat-item">
            <div className="stat-number">10K+</div>
            <div className="stat-label">Members</div>
          </div>
          <div className="stat-item">
            <div className="stat-number">54</div>
            <div className="stat-label">Countries</div>
          </div>
          <div className="stat-item">
            <div className="stat-number">50K+</div>
            <div className="stat-label">Conversations</div>
          </div>
          <div className="stat-item">
            <div className="stat-number">100+</div>
            <div className="stat-label">Languages</div>
          </div>
        </div>

        {/* Features */}
        <div className="section-title">
          <h3>Why LetsConnect?</h3>
          <p>Everything you need to stay connected with your community</p>
        </div>

        <div className="features">
          <div className="feature-card">
            <img 
              className="feature-card-img" 
              src="https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=600&q=80" 
              alt="Lagos Nigeria cityscape"
            />
            <div className="feature-card-body">
              <div className="feature-icon feature-icon-orange">📱</div>
              <h3>Share Your Story</h3>
              <p>Post photos, thoughts, and updates. Let your voice be heard across the continent and beyond.</p>
            </div>
          </div>

          <div className="feature-card">
            <img 
              className="feature-card-img" 
              src="https://images.unsplash.com/photo-1565791380713-1756b9a05343?w=600&q=80" 
              alt="Nairobi Kenya skyline"
            />
            <div className="feature-card-body">
              <div className="feature-icon feature-icon-green">🤝</div>
              <h3>Build Connections</h3>
              <p>Find friends, family, and like-minded people. Grow your network across all 54 African nations.</p>
            </div>
          </div>

          <div className="feature-card">
            <img 
              className="feature-card-img" 
              src="https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=600&q=80" 
              alt="Modern African professionals"
            />
            <div className="feature-card-body">
              <div className="feature-icon feature-icon-blue">💬</div>
              <h3>Engage & Discuss</h3>
              <p>Like, comment, and join conversations that matter. Be part of Africa's digital community.</p>
            </div>
          </div>

          <div className="feature-card">
            <img 
              className="feature-card-img" 
              src="https://images.unsplash.com/photo-1577948000111-9c970dfe3743?w=600&q=80" 
              alt="Accra Ghana modern city"
            />
            <div className="feature-card-body">
              <div className="feature-icon feature-icon-red">🔒</div>
              <h3>Safe & Secure</h3>
              <p>Your privacy matters. Full control over your data and who sees your content.</p>
            </div>
          </div>
        </div>

        {/* Community Gallery */}
        <div className="section-title">
          <h3>Our Community</h3>
          <p>Moments shared by members across Africa</p>
        </div>

        <div className="gallery">
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1611348586804-61bf6c080437?w=600&q=80" alt="Dar es Salaam Tanzania skyline" />
          </div>
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1591828988777-1e2e4a0e7a4d?w=600&q=80" alt="Kigali Rwanda modern city" />
          </div>
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1565791380713-1756b9a05343?w=600&q=80" alt="Nairobi business district" />
          </div>
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=600&q=80" alt="Lagos urban nightlife" />
          </div>
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1577948000111-9c970dfe3743?w=600&q=80" alt="Accra Ghana street scene" />
          </div>
        </div>
      </div>
    </div>
  );
}

export default Home;
