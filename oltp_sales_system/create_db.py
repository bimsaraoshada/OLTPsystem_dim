"""
Create OLTP Sales Database and Tables using SQLAlchemy
"""
from sqlalchemy import text
from config import engine_without_db, engine, DATABASE_NAME

def create_database():
    """Create the database and tables"""
    try:
        # Create database
        print(f"Creating database: {DATABASE_NAME}")
        with engine_without_db.connect() as connection:
            connection.execution_options(isolation_level="AUTOCOMMIT")
            connection.execute(text(f"CREATE DATABASE IF NOT EXISTS {DATABASE_NAME}"))
            print(f"Database {DATABASE_NAME} is ready")
        
        # Connect to the database
        with engine.connect() as connection:
            connection.execution_options(isolation_level="AUTOCOMMIT")
            
            # Create CUSTOMER table
            print("Creating tables...")
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS customer (
                    customer_id INT AUTO_INCREMENT PRIMARY KEY,
                    first_name VARCHAR(50) NOT NULL,
                    last_name VARCHAR(50) NOT NULL,
                    email VARCHAR(100) NOT NULL UNIQUE,
                    phone VARCHAR(20),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    INDEX idx_customer_email (email)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table CUSTOMER created successfully!")
            
            # Create PRODUCT table
            connection.execute(text("""
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
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table PRODUCT created successfully!")
            
            # Create LOCATION table
            connection.execute(text("""
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
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table LOCATION created successfully!")
            
            # Create SALES table
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS sales (
                    sale_id INT AUTO_INCREMENT PRIMARY KEY,
                    sale_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    quantity INT NOT NULL CHECK (quantity > 0),
                    unit_price DECIMAL(10, 2) NOT NULL,
                    total_amount DECIMAL(12, 2) NOT NULL,
                    customer_id INT,
                    product_id INT NOT NULL,
                    location_id INT NOT NULL,
                    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) 
                        REFERENCES customer(customer_id) ON DELETE RESTRICT,
                    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) 
                        REFERENCES product(product_id) ON DELETE RESTRICT,
                    CONSTRAINT fk_sales_location FOREIGN KEY (location_id) 
                        REFERENCES location(location_id) ON DELETE RESTRICT,
                    INDEX idx_sales_timestamp (sale_timestamp),
                    INDEX idx_sales_product (product_id),
                    INDEX idx_sales_location (location_id),
                    INDEX idx_sales_product_location_time (product_id, location_id, sale_timestamp),
                    INDEX idx_sales_product_location (product_id, location_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table SALES created successfully!")

            # Create DIM_DATE table
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS dim_date (
                    date_key INT PRIMARY KEY,
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
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table DIM_DATE created successfully!")

            # Create DIM_CUSTOMER table
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS dim_customer (
                    customer_key INT AUTO_INCREMENT PRIMARY KEY,
                    customer_id_nk INT NOT NULL UNIQUE,
                    full_name VARCHAR(120) NOT NULL,
                    email VARCHAR(100) NOT NULL,
                    phone VARCHAR(20),
                    created_at TIMESTAMP NOT NULL,
                    INDEX idx_dim_customer_email (email)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table DIM_CUSTOMER created successfully!")

            # Create DIM_PRODUCT table
            connection.execute(text("""
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
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table DIM_PRODUCT created successfully!")

            # Create DIM_LOCATION table
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS dim_location (
                    location_key INT AUTO_INCREMENT PRIMARY KEY,
                    location_id_nk INT NOT NULL UNIQUE,
                    location_name VARCHAR(100) NOT NULL,
                    city VARCHAR(50) NOT NULL,
                    address VARCHAR(200),
                    country VARCHAR(50) NOT NULL,
                    is_active BOOLEAN NOT NULL,
                    INDEX idx_dim_location_city_country (city, country)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table DIM_LOCATION created successfully!")

            # Create FACT_SALES_DW table
            connection.execute(text("""
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
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """))
            print("Table FACT_SALES_DW created successfully!")
            
            # Create view
            connection.execute(text("""
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
                JOIN location l ON s.location_id = l.location_id
            """))
            print("View vw_sales_details created successfully!")
            
            print("\n✓ All tables created successfully!")
        
    except Exception as e:
        print(f"✗ Error creating database: {e}")
        raise

if __name__ == "__main__":
    create_database()
