import React from 'react';
import { Link } from 'react-router-dom';
import './Home.css';

const Home = () => {
  const featuredCountries = [
    { name: 'Nigeria', flag: '🇳🇬', description: 'Dashiki, Ankara, Agbada', image: '/images/nigeria.jpg' },
    { name: 'Ghana', flag: '🇬🇭', description: 'Kente Cloth', image: 'https://images.unsplash.com/photo-1590736969955-71cc94901144?w=400' },
    { name: 'Senegal', flag: '🇸🇳', description: 'Boubou', image: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400' },
    { name: 'Morocco', flag: '🇲🇦', description: 'Kaftan', image: 'https://images.unsplash.com/photo-1595429089364-59a11f15c2d8?w=400' },
    { name: 'Kenya', flag: '🇰🇪', description: 'Maasai Shuka', image: 'https://images.unsplash.com/photo-1583521214690-73421a1829a9?w=400' },
    { name: 'South Africa', flag: '🇿🇦', description: 'Traditional Prints', image: 'https://images.unsplash.com/photo-1609505848912-b7c3b8b4beda?w=400' },
  ];

  return (
    <div className="home">
      {/* Hero Section */}
      <section className="hero">
          <div className="hero-overlay">
          <div className="container hero-content">
            <h1 className="hero-title">AfriqueOriginal</h1>
            <p className="hero-subtitle">
              Authentic African Fashion • Celebrating Culture & Style
            </p>
            <div className="hero-buttons">
              <Link to="/products" className="btn btn-primary btn-large">
                Shop Now
              </Link>
              <Link to="/register" className="btn btn-outline btn-large">
                Join Us
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Featured Countries */}
      <section className="featured-section">
        <div className="container">
          <h2 className="section-title">Shop by Country</h2>
          <p className="section-subtitle">
            Explore traditional and modern African fashion from various regions
          </p>
          <div className="countries-grid">
            {featuredCountries.map((country) => (
              <Link
                key={country.name}
                to={`/products?country=${country.name}`}
                className="country-card"
              >
                <div className="country-image">
                  <img src={country.image} alt={country.name} />
                  <div className="country-overlay">
                    <span className="country-flag">{country.flag}</span>
                  </div>
                </div>
                <div className="country-info">
                  <h3 className="country-name">{country.name}</h3>
                  <p className="country-description">{country.description}</p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="features-section">
        <div className="container">
          <h2 className="section-title">Why Choose Us</h2>
          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">✨</div>
              <h3>Authentic Designs</h3>
              <p>100% authentic African wear sourced directly from artisans</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">🚚</div>
              <h3>Fast Shipping</h3>
              <p>Quick and reliable delivery to your doorstep</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">💳</div>
              <h3>Secure Payment</h3>
              <p>Safe and secure checkout process</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">🌍</div>
              <h3>Pan-African</h3>
              <p>Products from multiple African countries</p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="cta-section">
        <div className="container">
          <div className="cta-content">
            <h2>Experience the Beauty of Africa</h2>
            <p>Join AfriqueOriginal - Where tradition meets contemporary style</p>
            <Link to="/products" className="btn btn-primary btn-large">
              Browse Collection
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;
