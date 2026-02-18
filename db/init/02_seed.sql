COPY tbl_customers FROM '/data/seed_data/customers.csv' DELIMITER ',' CSV HEADER;
COPY tbl_products FROM '/data/seed_data/products.csv' DELIMITER ',' CSV HEADER;
COPY tbl_orders FROM '/data/seed_data/orders.csv' DELIMITER ',' CSV HEADER;
COPY tbl_order_details FROM '/data/seed_data/order_details.csv' DELIMITER ',' CSV HEADER;

-- Resync sequences after bulk load (COPY does not update SERIAL sequences)
SELECT setval('tbl_customers_customer_id_seq', (SELECT MAX(customer_id) FROM tbl_customers));
SELECT setval('tbl_products_product_id_seq', (SELECT MAX(product_id) FROM tbl_products));
SELECT setval('tbl_orders_order_id_seq', (SELECT MAX(order_id) FROM tbl_orders));
SELECT setval('tbl_order_details_order_detail_id_seq', (SELECT MAX(order_detail_id) FROM tbl_order_details));
