-- products (원본 오타 'lenght' 교정)
INSERT INTO ods.products AS p
(product_id, product_category_name, product_name_length, product_description_length,
    product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
SELECT
    product_id, product_category_name,
    NULLIF(product_name_lenght,'')::int,
    NULLIF(product_description_lenght,'')::int,
    NULLIF(product_photos_qty,'')::int,
    NULLIF(product_weight_g,'')::int,
    NULLIF(product_length_cm,'')::int,
    NULLIF(product_height_cm,'')::int,
    NULLIF(product_width_cm,'')::int
FROM raw.products_raw
WHERE product_id IS NOT NULL
ON CONFLICT (product_id) DO UPDATE SET
    product_category_name = EXCLUDED.product_category_name,
    product_name_length = EXCLUDED.product_name_length,
    product_description_length = EXCLUDED.product_description_length,
    product_photos_qty = EXCLUDED.product_photos_qty,
    product_weight_g = EXCLUDED.product_weight_g,
    product_length_cm = EXCLUDED.product_length_cm,
    product_height_cm = EXCLUDED.product_height_cm,
    product_width_cm = EXCLUDED.product_width_cm;

-- sellers
INSERT INTO ods.sellers AS s
(seller_id, seller_zip_code_prefix, seller_city, seller_state)
SELECT seller_id, seller_zip_code_prefix, seller_city, seller_state
FROM raw.sellers_raw
WHERE seller_id IS NOT NULL
ON CONFLICT (seller_id) DO UPDATE SET
    seller_zip_code_prefix = EXCLUDED.seller_zip_code_prefix,
    seller_city = EXCLUDED.seller_city,
    seller_state = EXCLUDED.seller_state;

-- geolocation
INSERT INTO ods.geolocation AS g
(zip_code_prefix, lat, lng, city, state)
SELECT
    geolocation_zip_code_prefix,
    NULLIF(geolocation_lat,'')::numeric(10,6),
    NULLIF(geolocation_lng,'')::numeric(10,6),
    geolocation_city,
    geolocation_state
FROM raw.geolocation_raw
WHERE geolocation_zip_code_prefix IS NOT NULL
ON CONFLICT (zip_code_prefix, lat, lng) DO UPDATE SET
    city  = EXCLUDED.city,
    state = EXCLUDED.state;

-- product category translation
INSERT INTO ods.product_category_translation AS t
(product_category_name, product_category_name_english)
SELECT product_category_name, product_category_name_english
FROM raw.product_category_translation_raw
WHERE product_category_name IS NOT NULL
ON CONFLICT (product_category_name) DO UPDATE SET
    product_category_name_english = EXCLUDED.product_category_name_english;


