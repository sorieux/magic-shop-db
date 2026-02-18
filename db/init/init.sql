CREATE TABLE tbl_customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    gender VARCHAR(50) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other'))
);

CREATE TABLE tbl_products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE tbl_orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES tbl_customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    order_status VARCHAR(20) CHECK (order_status IN ('pending', 'completed', 'canceled')) NOT NULL
);

CREATE TABLE tbl_order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES tbl_orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES tbl_products(product_id) ON DELETE CASCADE,
    quantity INT NOT NULL CHECK (quantity > 0)
);

-- Indexes on foreign keys for better join performance
CREATE INDEX idx_orders_customer_id ON tbl_orders(customer_id);
CREATE INDEX idx_order_details_order_id ON tbl_order_details(order_id);
CREATE INDEX idx_order_details_product_id ON tbl_order_details(product_id);

-- Index on order_date for date range queries
CREATE INDEX idx_orders_order_date ON tbl_orders(order_date);

-- Index on order_status for filtering
CREATE INDEX idx_orders_order_status ON tbl_orders(order_status);

COPY tbl_customers FROM '/data/seed_data/customers.csv' DELIMITER ',' CSV HEADER;
COPY tbl_products FROM '/data/seed_data/products.csv' DELIMITER ',' CSV HEADER;
COPY tbl_orders FROM '/data/seed_data/orders.csv' DELIMITER ',' CSV HEADER;
COPY tbl_order_details FROM '/data/seed_data/order_details.csv' DELIMITER ',' CSV HEADER;

-- View: full order summary with customer name and total amount
CREATE VIEW vw_order_summary AS
SELECT
    o.order_id,
    c.name AS customer_name,
    c.gender,
    o.order_date,
    o.order_status,
    COUNT(od.order_detail_id) AS item_count,
    SUM(od.quantity * p.unit_price) AS total_amount
FROM tbl_orders o
JOIN tbl_customers c ON c.customer_id = o.customer_id
JOIN tbl_order_details od ON od.order_id = o.order_id
JOIN tbl_products p ON p.product_id = od.product_id
GROUP BY o.order_id, c.name, c.gender, o.order_date, o.order_status;

-- View: sales stats per product
CREATE VIEW vw_sales_by_product AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    COUNT(DISTINCT od.order_id) AS order_count,
    SUM(od.quantity) AS total_quantity_sold,
    SUM(od.quantity * p.unit_price) AS total_revenue
FROM tbl_products p
LEFT JOIN tbl_order_details od ON od.product_id = p.product_id
LEFT JOIN tbl_orders o ON o.order_id = od.order_id AND o.order_status = 'completed'
GROUP BY p.product_id, p.product_name, p.category, p.unit_price
ORDER BY total_revenue DESC NULLS LAST;

-- View: sales stats per category
CREATE VIEW vw_sales_by_category AS
SELECT
    p.category,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT od.order_id) AS order_count,
    SUM(od.quantity) AS total_quantity_sold,
    SUM(od.quantity * p.unit_price) AS total_revenue
FROM tbl_products p
LEFT JOIN tbl_order_details od ON od.product_id = p.product_id
LEFT JOIN tbl_orders o ON o.order_id = od.order_id AND o.order_status = 'completed'
GROUP BY p.category
ORDER BY total_revenue DESC NULLS LAST;

-- View: customer purchase statistics
CREATE VIEW vw_customer_stats AS
SELECT
    c.customer_id,
    c.name,
    c.gender,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'completed' THEN o.order_id END) AS completed_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'canceled' THEN o.order_id END) AS canceled_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'pending' THEN o.order_id END) AS pending_orders,
    COALESCE(SUM(CASE WHEN o.order_status = 'completed' THEN od.quantity * p.unit_price END), 0) AS total_spent,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date
FROM tbl_customers c
LEFT JOIN tbl_orders o ON o.customer_id = c.customer_id
LEFT JOIN tbl_order_details od ON od.order_id = o.order_id
LEFT JOIN tbl_products p ON p.product_id = od.product_id
GROUP BY c.customer_id, c.name, c.gender
ORDER BY total_spent DESC;

-- View: monthly revenue from completed orders
CREATE VIEW vw_monthly_revenue AS
SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(od.quantity * p.unit_price) AS revenue
FROM tbl_orders o
JOIN tbl_order_details od ON od.order_id = o.order_id
JOIN tbl_products p ON p.product_id = od.product_id
WHERE o.order_status = 'completed'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;
