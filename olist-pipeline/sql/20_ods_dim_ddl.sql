-- products
CREATE TABLE IF NOT EXISTS ods.products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT CHECK (product_weight_g >= 0),
    product_length_cm INT CHECK (product_length_cm >= 0),
    product_height_cm INT CHECK (product_height_cm >= 0),
    product_width_cm  INT CHECK (product_width_cm  >= 0)
);

-- sellers
CREATE TABLE IF NOT EXISTS ods.sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state CHAR(2)
);

-- geolocation
CREATE TABLE IF NOT EXISTS ods.geolocation (
    zip_code_prefix TEXT,
    lat NUMERIC(10,6),
    lng NUMERIC(10,6),
    city TEXT,
    state CHAR(2),
    PRIMARY KEY (zip_code_prefix, lat, lng)
);

-- translation
CREATE TABLE IF NOT EXISTS ods.product_category_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

-- FK 보완 (제품/셀러)
ALTER TABLE IF NOT EXISTS ods.order_items
    ADD CONSTRAINT IF NOT EXISTS fk_items_product
    FOREIGN KEY (product_id) REFERENCES ods.products(product_id)
    DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE IF NOT EXISTS ods.order_items
    ADD CONSTRAINT IF NOT EXISTS fk_items_seller
    FOREIGN KEY (seller_id) REFERENCES ods.sellers(seller_id)
    DEFERRABLE INITIALLY DEFERRED;
