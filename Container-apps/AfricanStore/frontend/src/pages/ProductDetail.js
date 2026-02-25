import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import './ProductDetail.css';

const ProductDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [product, setProduct] = useState(null);
  const [quantity, setQuantity] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const { addToCart } = useCart();
  const { user } = useAuth();

  const PRODUCTS_SERVICE_URL = process.env.REACT_APP_PRODUCTS_SERVICE_URL || 'http://localhost:3002';

  useEffect(() => {
    fetchProduct();
  }, [id]);

  const fetchProduct = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${PRODUCTS_SERVICE_URL}/api/products/${id}`);
      setProduct(response.data);
    } catch (error) {
      console.error('Error fetching product:', error);
      setError('Product not found');
    } finally {
      setLoading(false);
    }
  };

  const handleAddToCart = async () => {
    if (!user) {
      navigate('/login');
      return;
    }

    try {
      setError('');
      await addToCart(product.id, quantity);
      setSuccess('Added to cart successfully!');
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to add to cart');
    }
  };

  if (loading) {
    return <div className="spinner"></div>;
  }

  if (error && !product) {
    return (
      <div className="container">
        <div className="error-page">
          <h2>{error}</h2>
          <button onClick={() => navigate('/products')} className="btn btn-primary">
            Back to Products
          </button>
        </div>
      </div>
    );
  }

  if (!product) return null;

  return (
    <div className="product-detail-page">
      <div className="container">
        <button onClick={() => navigate('/products')} className="back-button">
          ← Back to Products
        </button>

        <div className="product-detail">
          <div className="product-image-section">
            <img
              src={product.image_url}
              alt={product.name}
              className="product-detail-image"
              onError={(e) => {
                e.target.src = 'https://via.placeholder.com/600x750?text=African+Wear';
              }}
            />
          </div>

          <div className="product-info-section">
            <div className="product-badges">
              <span className="badge badge-country">{product.country}</span>
              <span className="badge badge-category">{product.category_name}</span>
            </div>

            <h1 className="product-detail-name">{product.name}</h1>

            <div className="product-price-section">
              <span className="product-detail-price">${parseFloat(product.price).toFixed(2)}</span>
              <span className="product-stock-info">
                {product.stock_quantity > 0 ? (
                  <span className="in-stock">✓ {product.stock_quantity} in stock</span>
                ) : (
                  <span className="out-of-stock">✗ Out of stock</span>
                )}
              </span>
            </div>

            <p className="product-detail-description">{product.description}</p>

            {product.category_description && (
              <div className="category-info">
                <h3>About {product.category_name}</h3>
                <p>{product.category_description}</p>
              </div>
            )}

            {product.stock_quantity > 0 && (
              <div className="purchase-section">
                <div className="quantity-selector">
                  <label>Quantity:</label>
                  <div className="quantity-controls">
                    <button
                      onClick={() => setQuantity(Math.max(1, quantity - 1))}
                      className="quantity-btn"
                    >
                      -
                    </button>
                    <input
                      type="number"
                      min="1"
                      max={product.stock_quantity}
                      value={quantity}
                      onChange={(e) =>
                        setQuantity(
                          Math.min(product.stock_quantity, Math.max(1, parseInt(e.target.value) || 1))
                        )
                      }
                      className="quantity-input"
                    />
                    <button
                      onClick={() => setQuantity(Math.min(product.stock_quantity, quantity + 1))}
                      className="quantity-btn"
                    >
                      +
                    </button>
                  </div>
                </div>

                {error && <div className="error-message">{error}</div>}
                {success && <div className="success-message">{success}</div>}

                <button onClick={handleAddToCart} className="btn btn-primary btn-large btn-full">
                  🛒 Add to Cart
                </button>

                {!user && (
                  <p className="login-prompt">
                    Please <span onClick={() => navigate('/login')} className="login-link">login</span> to add items to cart
                  </p>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductDetail;
