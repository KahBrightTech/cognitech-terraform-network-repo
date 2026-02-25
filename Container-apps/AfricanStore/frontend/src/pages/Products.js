import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import axios from 'axios';
import ProductCard from '../components/ProductCard';
import './Products.css';

const Products = () => {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [countries, setCountries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    category: '',
    country: '',
    search: '',
  });

  const [searchParams] = useSearchParams();
  const PRODUCTS_SERVICE_URL = process.env.REACT_APP_PRODUCTS_SERVICE_URL || 'http://localhost:3002';

  useEffect(() => {
    const countryParam = searchParams.get('country');
    if (countryParam) {
      setFilters(prev => ({ ...prev, country: countryParam }));
    }
  }, [searchParams]);

  useEffect(() => {
    fetchProducts();
  }, [filters]);

  useEffect(() => {
    fetchCategories();
    fetchCountries();
  }, []);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (filters.category) params.append('category', filters.category);
      if (filters.country) params.append('country', filters.country);
      if (filters.search) params.append('search', filters.search);

      const response = await axios.get(`${PRODUCTS_SERVICE_URL}/api/products?${params}`);
      setProducts(response.data);
    } catch (error) {
      console.error('Error fetching products:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const response = await axios.get(`${PRODUCTS_SERVICE_URL}/api/categories`);
      setCategories(response.data);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const fetchCountries = async () => {
    try {
      const response = await axios.get(`${PRODUCTS_SERVICE_URL}/api/products/meta/countries`);
      setCountries(response.data);
    } catch (error) {
      console.error('Error fetching countries:', error);
    }
  };

  const handleFilterChange = (filterName, value) => {
    setFilters(prev => ({ ...prev, [filterName]: value }));
  };

  const clearFilters = () => {
    setFilters({ category: '', country: '', search: '' });
  };

  return (
    <div className="products-page">
      <div className="container">
        <div className="products-header">
          <h1>Our Collection</h1>
          <p>Discover authentic African wear from various countries and cultures</p>
        </div>

        <div className="products-layout">
          {/* Filters Sidebar */}
          <aside className="filters-sidebar">
            <div className="filters-card">
              <div className="filters-header">
                <h3>Filters</h3>
                {(filters.category || filters.country || filters.search) && (
                  <button onClick={clearFilters} className="clear-filters">
                    Clear All
                  </button>
                )}
              </div>

              {/* Search */}
              <div className="filter-section">
                <label className="filter-label">Search</label>
                <input
                  type="text"
                  className="filter-search"
                  placeholder="Search products..."
                  value={filters.search}
                  onChange={(e) => handleFilterChange('search', e.target.value)}
                />
              </div>

              {/* Country Filter */}
              <div className="filter-section">
                <label className="filter-label">Country</label>
                <select
                  className="filter-select"
                  value={filters.country}
                  onChange={(e) => handleFilterChange('country', e.target.value)}
                >
                  <option value="">All Countries</option>
                  {countries.map((country) => (
                    <option key={country} value={country}>
                      {country}
                    </option>
                  ))}
                </select>
              </div>

              {/* Category Filter */}
              <div className="filter-section">
                <label className="filter-label">Category</label>
                <select
                  className="filter-select"
                  value={filters.category}
                  onChange={(e) => handleFilterChange('category', e.target.value)}
                >
                  <option value="">All Categories</option>
                  {categories.map((category) => (
                    <option key={category.id} value={category.id}>
                      {category.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </aside>

          {/* Products Grid */}
          <div className="products-content">
            {loading ? (
              <div className="spinner"></div>
            ) : products.length === 0 ? (
              <div className="no-products">
                <h3>No products found</h3>
                <p>Try adjusting your filters</p>
              </div>
            ) : (
              <>
                <div className="products-count">
                  {products.length} {products.length === 1 ? 'product' : 'products'} found
                </div>
                <div className="products-grid">
                  {products.map((product) => (
                    <ProductCard key={product.id} product={product} />
                  ))}
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Products;
