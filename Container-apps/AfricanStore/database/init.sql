-- Create tables for African Wear E-commerce Platform

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category_id INTEGER REFERENCES categories(id),
    country VARCHAR(100) NOT NULL,
    image_url TEXT,
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cart table
CREATE TABLE IF NOT EXISTS carts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Cart items table
CREATE TABLE IF NOT EXISTS cart_items (
    id SERIAL PRIMARY KEY,
    cart_id INTEGER REFERENCES carts(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(cart_id, product_id)
);

-- Insert sample categories
INSERT INTO categories (name, country, description) VALUES
('Dashiki', 'Nigeria', 'Traditional colorful garment worn in West Africa'),
('Kente', 'Ghana', 'Colorful Ghanaian ceremonial cloth made of silk and cotton'),
('Boubou', 'Senegal', 'Flowing wide-sleeved robe worn by both men and women'),
('Kaftan', 'Morocco', 'Traditional North African robe with full sleeves'),
('Ankara', 'Nigeria', 'Vibrant African wax print fabric and clothing'),
('Agbada', 'Nigeria', 'Wide-sleeved flowing robe worn by men'),
('Wrapper', 'Multiple', 'Traditional wrap-around skirt worn in various African countries'),
('Shuka', 'Kenya', 'Traditional Maasai cloth with distinctive checked pattern');

-- Insert sample products with diverse African wear
INSERT INTO products (name, description, price, category_id, country, image_url, stock_quantity) VALUES
-- Nigerian Dashiki
('Men''s Blue Dashiki Shirt', 'Handcrafted traditional Nigerian Dashiki with intricate embroidery', 45.99, 1, 'Nigeria', '/images/countries/Nigeria/pic1.jpg', 25),
('Women''s Red Dashiki Dress', 'Beautiful red Dashiki dress with gold embroidery patterns', 65.99, 1, 'Nigeria', '/images/countries/Nigeria/pic2.jpg', 18),

-- Ghanaian Kente
('Royal Kente Cloth', 'Authentic handwoven Kente cloth in royal colors', 120.00, 2, 'Ghana', 'https://images.unsplash.com/photo-1590736969955-71cc94901144?w=500', 12),
('Kente Stole', 'Beautiful Kente graduation stole with traditional patterns', 55.00, 2, 'Ghana', 'https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?w=500', 30),
('Women''s Kente Dress', 'Elegant dress made from authentic Kente fabric', 95.00, 2, 'Ghana', 'https://images.unsplash.com/photo-1591258370814-01609b341790?w=500', 15),

-- Senegalese Boubou
('Men''s White Boubou', 'Classic white Senegalese Boubou with gold embroidery', 85.00, 3, 'Senegal', 'https://images.unsplash.com/photo-1578632292335-df3abbb0d586?w=500', 20),
('Women''s Purple Boubou', 'Flowing purple Boubou with intricate beadwork', 105.00, 3, 'Senegal', 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=500', 14),

-- Moroccan Kaftan
('Luxury Moroccan Kaftan', 'Ornate Moroccan Kaftan with detailed embroidery', 150.00, 4, 'Morocco', 'https://images.unsplash.com/photo-1617922001439-4a2e6562f328?w=500', 8),
('Simple Kaftan Dress', 'Comfortable everyday Kaftan in vibrant colors', 75.00, 4, 'Morocco', 'https://images.unsplash.com/photo-1595429089364-59a11f15c2d8?w=500', 22),

-- Nigerian Ankara
('Ankara Print Dress', 'Colorful Ankara print dress with modern cut', 55.00, 5, 'Nigeria', '/images/countries/Nigeria/pic3.jpg', 35),
('Men''s Ankara Shirt', 'Stylish Ankara print shirt for men', 42.00, 5, 'Nigeria', '/images/countries/Nigeria/pic4.jpg', 28),
('Ankara Jumpsuit', 'Modern Ankara print jumpsuit for women', 72.00, 5, 'Nigeria', 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=500', 16),

-- Nigerian Agbada
('Royal Blue Agbada', 'Traditional Nigerian Agbada set with matching cap', 180.00, 6, 'Nigeria', '/images/countries/Nigeria/pic5.jpg', 10),
('Gold Agbada Set', 'Luxurious gold Agbada with intricate embroidery', 220.00, 6, 'Nigeria', 'https://images.unsplash.com/photo-1581338834647-b0fb40704e21?w=500', 7),

-- Wrapper/Wrap Skirts
('Traditional Wrapper Set', 'Authentic African wrapper with matching blouse', 68.00, 7, 'Multiple', 'https://images.unsplash.com/photo-1585487000143-7b0b41e9f7be?w=500', 25),
('Ankara Wrapper', 'Colorful Ankara print wrapper and head tie set', 48.00, 7, 'Nigeria', '/images/countries/Nigeria/pic6.jpg', 32),

-- Kenyan Shuka
('Maasai Shuka Blanket', 'Traditional Maasai Shuka cloth in classic red check', 38.00, 8, 'Kenya', 'https://images.unsplash.com/photo-1583521214690-73421a1829a9?w=500', 40),
('Shuka Wrap Dress', 'Modern dress made from traditional Shuka fabric', 62.00, 8, 'Kenya', 'https://images.unsplash.com/photo-1618453292507-4959ece6429e?w=500', 19);

-- Create indexes for better performance
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_country ON products(country);
CREATE INDEX idx_cart_user ON carts(user_id);
CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX idx_cart_items_product ON cart_items(product_id);
