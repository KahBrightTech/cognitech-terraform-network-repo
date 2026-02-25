import React, { createContext, useState, useContext, useEffect } from 'react';
import axios from 'axios';
import { useAuth } from './AuthContext';

const CartContext = createContext();

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
};

export const CartProvider = ({ children }) => {
  const [cart, setCart] = useState({ items: [], total: 0, itemCount: 0 });
  const [loading, setLoading] = useState(false);
  const { user, getToken } = useAuth();

  const CART_SERVICE_URL = process.env.REACT_APP_CART_SERVICE_URL || 'http://localhost:3003';

  useEffect(() => {
    if (user) {
      fetchCart();
    } else {
      setCart({ items: [], total: 0, itemCount: 0 });
    }
  }, [user]);

  const fetchCart = async () => {
    if (!user) return;
    
    try {
      setLoading(true);
      const token = getToken();
      const response = await axios.get(`${CART_SERVICE_URL}/api/cart`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCart(response.data);
    } catch (error) {
      console.error('Error fetching cart:', error);
    } finally {
      setLoading(false);
    }
  };

  const addToCart = async (productId, quantity = 1) => {
    if (!user) {
      throw new Error('Please login to add items to cart');
    }

    try {
      const token = getToken();
      await axios.post(
        `${CART_SERVICE_URL}/api/cart/items`,
        { productId, quantity },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      await fetchCart();
    } catch (error) {
      throw error;
    }
  };

  const updateCartItem = async (itemId, quantity) => {
    if (!user) return;

    try {
      const token = getToken();
      await axios.put(
        `${CART_SERVICE_URL}/api/cart/items/${itemId}`,
        { quantity },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      await fetchCart();
    } catch (error) {
      throw error;
    }
  };

  const removeFromCart = async (itemId) => {
    if (!user) return;

    try {
      const token = getToken();
      await axios.delete(`${CART_SERVICE_URL}/api/cart/items/${itemId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      await fetchCart();
    } catch (error) {
      throw error;
    }
  };

  const clearCart = async () => {
    if (!user) return;

    try {
      const token = getToken();
      await axios.delete(`${CART_SERVICE_URL}/api/cart`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCart({ items: [], total: 0, itemCount: 0 });
    } catch (error) {
      throw error;
    }
  };

  return (
    <CartContext.Provider
      value={{
        cart,
        loading,
        addToCart,
        updateCartItem,
        removeFromCart,
        clearCart,
        refreshCart: fetchCart,
      }}
    >
      {children}
    </CartContext.Provider>
  );
};
