import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import './Cart.css';

const Cart = () => {
  const { cart, loading, updateCartItem, removeFromCart, clearCart } = useCart();
  const navigate = useNavigate();
  const [updatingItems, setUpdatingItems] = useState({});

  const handleCheckout = () => {
    // Show confirmation and clear cart
    if (window.confirm(`Proceed with checkout for $${cart.total}?\n\nThis is a demo - no actual payment will be processed.`)) {
      alert('Order placed successfully! 🎉\n\nThank you for shopping at AfriqueOriginal!');
      clearCart();
      navigate('/products');
    }
  };

  const handleUpdateQuantity = async (itemId, newQuantity) => {
    if (newQuantity < 1) return;

    try {
      setUpdatingItems(prev => ({ ...prev, [itemId]: true }));
      await updateCartItem(itemId, newQuantity);
    } catch (error) {
      console.error('Error updating quantity:', error);
    } finally {
      setUpdatingItems(prev => ({ ...prev, [itemId]: false }));
    }
  };

  const handleRemoveItem = async (itemId) => {
    if (window.confirm('Remove this item from cart?')) {
      try {
        await removeFromCart(itemId);
      } catch (error) {
        console.error('Error removing item:', error);
      }
    }
  };

  const handleClearCart = async () => {
    if (window.confirm('Clear all items from cart?')) {
      try {
        await clearCart();
      } catch (error) {
        console.error('Error clearing cart:', error);
      }
    }
  };

  if (loading) {
    return <div className="spinner"></div>;
  }

  if (!cart.items || cart.items.length === 0) {
    return (
      <div className="container">
        <div className="empty-cart">
          <div className="empty-cart-icon">🛒</div>
          <h2>Your cart is empty</h2>
          <p>Start shopping to add items to your cart</p>
          <button onClick={() => navigate('/products')} className="btn btn-primary btn-large">
            Browse Products
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="cart-page">
      <div className="container">
        <div className="cart-header">
          <h1>Shopping Cart</h1>
          <button onClick={handleClearCart} className="btn btn-outline">
            Clear Cart
          </button>
        </div>

        <div className="cart-layout">
          <div className="cart-items">
            {cart.items.map((item) => (
              <div key={item.id} className="cart-item">
                <div className="cart-item-image">
                  <img
                    src={item.image_url}
                    alt={item.name}
                    onError={(e) => {
                      e.target.src = 'https://via.placeholder.com/150?text=Product';
                    }}
                  />
                </div>

                <div className="cart-item-details">
                  <h3 className="cart-item-name">{item.name}</h3>
                  <p className="cart-item-description">{item.description}</p>
                  <p className="cart-item-price">${parseFloat(item.price).toFixed(2)} each</p>
                </div>

                <div className="cart-item-actions">
                  <div className="cart-quantity-controls">
                    <button
                      onClick={() => handleUpdateQuantity(item.id, item.quantity - 1)}
                      className="quantity-btn"
                      disabled={updatingItems[item.id]}
                    >
                      -
                    </button>
                    <span className="quantity-display">{item.quantity}</span>
                    <button
                      onClick={() => handleUpdateQuantity(item.id, item.quantity + 1)}
                      className="quantity-btn"
                      disabled={updatingItems[item.id] || item.quantity >= item.stock_quantity}
                    >
                      +
                    </button>
                  </div>

                  <div className="cart-item-subtotal">
                    <span className="subtotal-label">Subtotal:</span>
                    <span className="subtotal-amount">${parseFloat(item.subtotal).toFixed(2)}</span>
                  </div>

                  <button
                    onClick={() => handleRemoveItem(item.id)}
                    className="remove-btn"
                    disabled={updatingItems[item.id]}
                  >
                    Remove
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="cart-summary">
            <div className="summary-card">
              <h2>Order Summary</h2>

              <div className="summary-row">
                <span>Items ({cart.itemCount}):</span>
                <span>${cart.total}</span>
              </div>

              <div className="summary-row">
                <span>Shipping:</span>
                <span className="free-shipping">FREE</span>
              </div>

              <div className="summary-divider"></div>

              <div className="summary-row summary-total">
                <span>Total:</span>
                <span>${cart.total}</span>
              </div>

              <button className="btn btn-primary btn-full btn-large checkout-btn" onClick={handleCheckout}>
                Proceed to Checkout
              </button>

              <button
                onClick={() => navigate('/products')}
                className="btn btn-outline btn-full mt-2"
              >
                Continue Shopping
              </button>

              <div className="payment-info">
                <p>🔒 Secure payment processing</p>
                <p>✓ Free shipping on all orders</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Cart;
