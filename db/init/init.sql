CREATE TABLE tbl_customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    gender VARCHAR(50) NOT NULL
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

COPY tbl_customers FROM '/data/seed_data/customers.csv' DELIMITER ',' CSV HEADER;
COPY tbl_products FROM '/data/seed_data/products.csv' DELIMITER ',' CSV HEADER;
COPY tbl_orders FROM '/data/seed_data/orders.csv' DELIMITER ',' CSV HEADER;
COPY tbl_order_details FROM '/data/seed_data/order_details.csv' DELIMITER ',' CSV HEADER;

