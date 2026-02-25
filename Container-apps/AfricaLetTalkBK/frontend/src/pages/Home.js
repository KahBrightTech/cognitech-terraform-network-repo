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
          <h3>Why LetsConnectAfrika?</h3>
          <p>Everything you need to stay connected with your community</p>
        </div>

        <div className="features">
          <div className="feature-card">
            <img 
              className="feature-card-img" 
              src="https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=600&q=80" 
              alt="Kilimanjaro at sunset"
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
              src="https://images.unsplash.com/photo-1535941339077-2dd1c7963098?w=600&q=80" 
              alt="Great Pyramids of Giza"
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
              src="https://images.unsplash.com/photo-1489392191049-fc10c97e64b6?w=600&q=80" 
              alt="African safari elephants"
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
              src="https://images.unsplash.com/photo-1549366021-9f761d450615?w=600&q=80" 
              alt="Table Mountain Cape Town"
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
            <img src="https://images.unsplash.com/photo-1516426122078-c23e76319801?w=600&q=80" alt="African safari wildlife" />
          </div>
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=600&q=80" alt="Victoria Falls Zimbabwe" />
          </div>
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1484318571209-661cf29a69c3?w=600&q=80" alt="African sunset savanna" />
          </div>
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1493246507139-91e8fad9978e?w=600&q=80" alt="Majestic African landscape" />
          </div>
          <div className="gallery-item">
            <img src="https://images.unsplash.com/photo-1518709766631-a6a7f45921c3?w=600&q=80" alt="Marrakech Morocco" />
          </div>
        </div>
      </div>
    </div>
  );
}

export default Home;
