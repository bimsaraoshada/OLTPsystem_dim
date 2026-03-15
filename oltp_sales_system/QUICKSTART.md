# Quick Start Guide - OLTP Sales System

Follow these steps to get the OLTP sales system up and running.

## Step 1: Install MySQL Server

If you don't have MySQL installed:

**Windows:**
1. Download MySQL Installer from https://dev.mysql.com/downloads/installer/
2. Run installer and choose "Developer Default"
3. Set a root password during installation (remember this!)
4. Complete installation

**Verify Installation:**
```powershell
mysql --version
```

## Step 2: Install Python Dependencies

Open PowerShell in the project directory and run:

```powershell
pip install -r requirements.txt
```

This installs:
- `mysql-connector-python`: MySQL database connector
- `faker`: Generate realistic sample data

## Step 3: Configure Database Connection

1. Open `config.py` in your editor
2. Update the password field:

```python
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'YOUR_MYSQL_ROOT_PASSWORD',  # ← Change this!
    'port': 3306
}
```

## Step 4: Test MySQL Connection

Run the connection test script:

```powershell
python test_connection.py
```

Expected output:
```
✓ MySQL connection successful!
MySQL version: 8.x.x
```

If you see an error, verify:
- MySQL service is running
- Password in config.py is correct
- MySQL is listening on port 3306

## Step 5: Create Database and Tables

Run the database creation script:

```powershell
python create_db.py
```

Expected output:
```
Creating database: oltp_sales_db
Database created successfully!
Creating tables...
Table CUSTOMER created successfully!
Table PRODUCT created successfully!
Table LOCATION created successfully!
Table SALES created successfully!
All tables created successfully!
```

## Step 6: Load Sample Data

Generate and insert sample data:

```powershell
python sample_data.py
```

Expected output:
```
Inserting 100 customers...
Inserted 100 customers successfully!
Inserting 20 products...
Inserted 20 products successfully!
Inserting 10 locations...
Inserted 10 locations successfully!
Inserting 1000 sales records...
Inserted 1000 sales records successfully!
Sample data loaded successfully!
```

This creates:
- **100 customers** with realistic names and emails
- **20 products** across Electronics, Clothing, Home & Garden, Sports
- **10 locations** in USA, UK, Canada, Germany, Australia
- **1000 sales transactions** spanning the last 2 years

## Step 7: Run Sample Queries

Execute the demonstration queries:

```powershell
python queries.py
```

This will run both required queries and display results.

## Step 8: Verify in MySQL

(Optional) Connect to MySQL directly to explore:

```powershell
mysql -u root -p
```

```sql
USE oltp_sales_db;

-- View table structure
DESCRIBE customer;
DESCRIBE product;
DESCRIBE location;
DESCRIBE sales;

-- Count records
SELECT COUNT(*) FROM customer;
SELECT COUNT(*) FROM product;
SELECT COUNT(*) FROM location;
SELECT COUNT(*) FROM sales;

-- Sample query
SELECT 
    p.product_name,
    l.location_name,
    COUNT(*) as num_sales,
    SUM(s.total_amount) as total_revenue
FROM sales s
JOIN product p ON s.product_id = p.product_id
JOIN location l ON s.location_id = l.location_id
GROUP BY p.product_name, l.location_name
ORDER BY total_revenue DESC
LIMIT 10;
```

## Troubleshooting

### Error: "Access denied for user 'root'@'localhost'"
**Solution**: Check password in `config.py` matches MySQL root password

### Error: "Can't connect to MySQL server"
**Solution**: 
1. Verify MySQL service is running:
   ```powershell
   Get-Service MySQL*
   ```
2. Start if stopped:
   ```powershell
   Start-Service MySQL80  # or your MySQL service name
   ```

### Error: "Module not found: mysql.connector"
**Solution**: Install requirements again:
```powershell
pip install --upgrade mysql-connector-python
```

### Error: "Database already exists"
**Solution**: This is safe to ignore. The script will use the existing database.

## Next Steps

1. **Explore the data**: Run `queries.py` with different parameters
2. **Add your own data**: Modify `sample_data.py` to insert custom records
3. **Create new queries**: Use `queries.py` as a template
4. **Review the schema**: Check `schema.sql` to understand table structure

## Useful Commands

**Reset database:**
```sql
DROP DATABASE oltp_sales_db;
```
Then run `python create_db.py` again.

**Check table sizes:**
```sql
SELECT 
    table_name,
    table_rows,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS "Size (MB)"
FROM information_schema.TABLES
WHERE table_schema = 'oltp_sales_db';
```

**View all indexes:**
```sql
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS COLUMNS
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'oltp_sales_db'
GROUP BY TABLE_NAME, INDEX_NAME;
```

## Support

For issues or questions:
1. Review `ATTRIBUTES_SUMMARY.md` for table design details
2. Check `README.md` for architecture overview
3. Examine `schema.sql` for exact DDL statements

Happy querying! 🚀
