-- ============================================
-- OLTP Sales System - Database Schema
-- ============================================
-- Purpose: Online Transaction Processing database
-- for managing customer sales across locations
-- ============================================

-- Create database
CREATE DATABASE IF NOT EXISTS oltp_sales_db;
USE oltp_sales_db;

-- ============================================
-- TABLE: CUSTOMER
-- ============================================
-- Stores customer information
CREATE TABLE IF NOT EXISTS customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_customer_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: PRODUCT
-- ============================================
-- Stores product catalog
CREATE TABLE IF NOT EXISTS product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_product_category (category),
    INDEX idx_product_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: LOCATION
-- ============================================
-- Stores sales location/store information
CREATE TABLE IF NOT EXISTS location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    address VARCHAR(200),
    country VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_location_city (city),
    INDEX idx_location_country (country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: SALES (Fact Table)
-- ============================================
-- Stores all sales transactions
CREATE TABLE IF NOT EXISTS sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    sale_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL,
    customer_id INT,
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    
    -- Foreign key constraints
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) 
        REFERENCES customer(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) 
        REFERENCES product(product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sales_location FOREIGN KEY (location_id) 
        REFERENCES location(location_id) ON DELETE RESTRICT,
    
    -- Performance indexes for OLTP queries
    INDEX idx_sales_timestamp (sale_timestamp),
    INDEX idx_sales_product (product_id),
    INDEX idx_sales_location (location_id),
    
    -- Composite indexes for specific query patterns
    INDEX idx_sales_product_location_time (product_id, location_id, sale_timestamp),
    INDEX idx_sales_product_location (product_id, location_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- DIMENSIONAL MODEL TABLES (STAR SCHEMA)
-- ============================================

-- Date dimension
CREATE TABLE IF NOT EXISTS dim_date (
    date_key INT PRIMARY KEY, -- YYYYMMDD
    full_date DATE NOT NULL UNIQUE,
    day_of_month TINYINT NOT NULL,
    month_number TINYINT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter_number TINYINT NOT NULL,
    year_number SMALLINT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    INDEX idx_dim_date_full_date (full_date),
    INDEX idx_dim_date_year_month (year_number, month_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Customer dimension
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id_nk INT NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP NOT NULL,
    INDEX idx_dim_customer_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Product dimension
CREATE TABLE IF NOT EXISTS dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id_nk INT NOT NULL UNIQUE,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    base_unit_price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN NOT NULL,
    INDEX idx_dim_product_category (category),
    INDEX idx_dim_product_brand (brand)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Location dimension
CREATE TABLE IF NOT EXISTS dim_location (
    location_key INT AUTO_INCREMENT PRIMARY KEY,
    location_id_nk INT NOT NULL UNIQUE,
    location_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    address VARCHAR(200),
    country VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL,
    INDEX idx_dim_location_city_country (city, country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Warehouse fact table
CREATE TABLE IF NOT EXISTS fact_sales_dw (
    sales_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    sale_id_nk INT NOT NULL UNIQUE,
    date_key INT NOT NULL,
    customer_key INT,
    product_key INT NOT NULL,
    location_key INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL,
    sale_timestamp TIMESTAMP NOT NULL,
    CONSTRAINT fk_fact_date FOREIGN KEY (date_key)
        REFERENCES dim_date(date_key) ON DELETE RESTRICT,
    CONSTRAINT fk_fact_customer FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key) ON DELETE RESTRICT,
    CONSTRAINT fk_fact_product FOREIGN KEY (product_key)
        REFERENCES dim_product(product_key) ON DELETE RESTRICT,
    CONSTRAINT fk_fact_location FOREIGN KEY (location_key)
        REFERENCES dim_location(location_key) ON DELETE RESTRICT,
    INDEX idx_fact_product_location_date (product_key, location_key, date_key),
    INDEX idx_fact_sale_timestamp (sale_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: Sales with full details
CREATE OR REPLACE VIEW vw_sales_details AS
SELECT 
    s.sale_id,
    s.sale_timestamp,
    s.quantity,
    s.unit_price,
    s.total_amount,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email AS customer_email,
    p.product_id,
    p.product_name,
    p.category AS product_category,
    p.brand AS product_brand,
    l.location_id,
    l.location_name,
    l.city,
    l.country
FROM sales s
LEFT JOIN customer c ON s.customer_id = c.customer_id
JOIN product p ON s.product_id = p.product_id
JOIN location l ON s.location_id = l.location_id;

-- ============================================
-- USEFUL STATISTICS QUERIES
-- ============================================

-- Query 1: Sales for a given product by location over a period of time
-- Example usage (replace with actual values):
/*
SELECT 
    p.product_name,
    l.location_name,
    l.city,
    l.country,
    COUNT(*) AS number_of_sales,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_sale_amount,
    MIN(s.sale_timestamp) AS first_sale,
    MAX(s.sale_timestamp) AS last_sale
FROM sales s
JOIN product p ON s.product_id = p.product_id
JOIN location l ON s.location_id = l.location_id
WHERE p.product_id = 1  -- Replace with actual product_id
  AND l.location_id = 2  -- Replace with actual location_id
  AND s.sale_timestamp BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY p.product_name, l.location_name, l.city, l.country;
*/

-- Query 2: Maximum number of sales for a given product at a location
-- Example usage (replace with actual values):
/*
SELECT 
    p.product_name,
    l.location_name,
    DATE(s.sale_timestamp) AS sale_date,
    COUNT(*) AS number_of_sales,
    SUM(s.quantity) AS total_quantity
FROM sales s
JOIN product p ON s.product_id = p.product_id
JOIN location l ON s.location_id = l.location_id
WHERE p.product_id = 1  -- Replace with actual product_id
  AND l.location_id = 2  -- Replace with actual location_id
  AND s.sale_timestamp BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY p.product_name, l.location_name, DATE(s.sale_timestamp)
ORDER BY number_of_sales DESC
LIMIT 1;
*/
