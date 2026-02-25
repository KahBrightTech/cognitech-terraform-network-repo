import React from 'react';
import { Link } from 'react-router-dom';

function NotFound() {
  return (
    <div className="container">
      <div className="not-found">
        <h1>404</h1>
        <h2>Page Not Found</h2>
        <p>The page you're looking for doesn't exist or has been moved.</p>
        <Link to="/" className="btn-primary" style={{ display: 'inline-block', width: 'auto', padding: '12px 32px', textDecoration: 'none' }}>
          Go Home
        </Link>
      </div>
    </div>
  );
}

export default NotFound;
