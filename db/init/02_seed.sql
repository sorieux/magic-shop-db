COPY tbl_customers FROM '/data/seed_data/customers.csv' DELIMITER ',' CSV HEADER;
COPY tbl_products FROM '/data/seed_data/products.csv' DELIMITER ',' CSV HEADER;
COPY tbl_orders FROM '/data/seed_data/orders.csv' DELIMITER ',' CSV HEADER;
COPY tbl_order_details FROM '/data/seed_data/order_details.csv' DELIMITER ',' CSV HEADER;
