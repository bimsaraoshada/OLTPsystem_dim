# OLTP Sales System

A complete Online Transaction Processing (OLTP) database system for managing customer sales across multiple locations, now extended with a dimensional (star schema) layer for analytics.

## 📋 Project Overview

This project implements a normalized OLTP database design with four core tables:
- **CUSTOMER**: Customer information
- **PRODUCT**: Product catalog
- **LOCATION**: Store/sales locations
- **SALES**: Transaction records (fact table)

It also includes a warehouse-oriented star schema:
- **DIM_DATE**: Calendar attributes for time analysis
- **DIM_CUSTOMER**: Customer analytics dimension
- **DIM_PRODUCT**: Product analytics dimension
- **DIM_LOCATION**: Location analytics dimension
- **FACT_SALES_DW**: Analytical sales fact table keyed by dimensions

## 🎯 Supported Queries

The database is optimized to efficiently answer:

1. **Sales for a given product by location over a period of time**
   - Filter by product, location, and date range
   - Returns aggregated sales metrics

2. **Maximum number of sales for a given product over time for a given location**
   - Identifies peak sales periods
   - Supports inventory and demand planning

## 🗄️ Database Schema

```
CUSTOMER (customer_id, first_name, last_name, email, phone, created_at, updated_at)
PRODUCT (product_id, product_name, category, brand, unit_price, is_active, created_at, updated_at)
LOCATION (location_id, location_name, city, address, country, is_active, created_at, updated_at)
SALES (sale_id, sale_timestamp, quantity, unit_price, total_amount, customer_id, product_id, location_id)

DIM_DATE (date_key, full_date, day_of_month, month_number, month_name, quarter_number, year_number, day_name, is_weekend)
DIM_CUSTOMER (customer_key, customer_id_nk, full_name, email, phone, created_at)
DIM_PRODUCT (product_key, product_id_nk, product_name, category, brand, base_unit_price, is_active)
DIM_LOCATION (location_key, location_id_nk, location_name, city, address, country, is_active)
FACT_SALES_DW (sales_key, sale_id_nk, date_key, customer_key, product_key, location_key, quantity, unit_price, total_amount, sale_timestamp)
```

See [ATTRIBUTES_SUMMARY.md](ATTRIBUTES_SUMMARY.md) for detailed attribute specifications.

## 🚀 Quick Start

### Prerequisites
- Python 3.7+
- MySQL Server 5.7+ or 8.0+
- pip (Python package manager)

### Installation

1. **Install Python dependencies**
```powershell
pip install -r requirements.txt
```

2. **Configure database connection**
Edit `config.py` and update your MySQL credentials:
```python
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'your_password_here',  # UPDATE THIS
    'port': 3306
}
```

3. **Test database connection**
```powershell
python test_connection.py
```

4. **Create database and tables**
```powershell
python create_db.py
```

5. **Load sample data**
```powershell
python sample_data.py
```

6. **Run sample queries**
```powershell
python queries.py
```

## 📁 File Structure

```
oltp_sales_system/
├── README.md                    # This file
├── ATTRIBUTES_SUMMARY.md        # Detailed table attributes
├── QUICKSTART.md                # Step-by-step setup guide
├── requirements.txt             # Python dependencies
├── config.py                    # Database configuration
├── schema.sql                   # SQL schema definition
├── test_connection.py           # Database connection test
├── create_db.py                 # Database setup script
├── sample_data.py               # Sample data generator
└── queries.py                   # Query demonstrations
```

## 💻 Usage Examples

### Query 1: Sales by Product, Location, and Time Period

```python
from queries import get_sales_by_product_location_time

results = get_sales_by_product_location_time(
    product_id=1,
    location_id=2,
    start_date='2024-01-01',
    end_date='2024-12-31'
)
```

### Query 2: Maximum Sales for Product at Location

```python
from queries import get_max_sales_for_product_location

results = get_max_sales_for_product_location(
    product_id=1,
    location_id=2,
    start_date='2024-01-01',
    end_date='2024-12-31'
)
```

## 🔧 OLTP Design Features

- ✅ **ACID Compliance**: Full transaction support
- ✅ **Normalized Design**: 3NF schema minimizes data redundancy
- ✅ **Referential Integrity**: Foreign key constraints
- ✅ **Optimized Indexes**: Strategic indexing for query performance
- ✅ **Audit Trail**: Timestamp tracking on all tables
- ✅ **Data Quality**: NOT NULL and CHECK constraints
- ✅ **Scalability**: Auto-increment primary keys

## 📊 Sample Data

The `sample_data.py` script generates:
- 100 customers
- 20 products across 4 categories
- 10 locations across 5 countries
- 1,000 sales transactions
- Dimension rows derived from OLTP source tables
- 1,000 `fact_sales_dw` rows mapped to dimensional keys

## 🔍 Performance Optimization

Key indexes for OLTP performance:

```sql
-- For Query 1: Product sales by location over time
INDEX idx_sales_product_location_time (product_id, location_id, sale_timestamp)

-- For Query 2: Maximum sales analysis
INDEX idx_sales_product_location (product_id, location_id)

-- General performance
INDEX idx_sales_timestamp (sale_timestamp)
```

## 📝 Notes

- All timestamps are stored in UTC
- Prices are stored with 2 decimal precision
- Email addresses must be unique per customer
- Foreign keys use ON DELETE RESTRICT to prevent orphaned records

## 🤝 Contributing

This is an educational project for OLTP database design. Feel free to extend with additional features:
- Payment processing
- Inventory management
- Customer loyalty programs
- Multi-currency support

## 📄 License

Educational use only.
