
USE APPLICATION PACKAGE {{package_name}};

CREATE SCHEMA IF NOT EXISTS app_data;
USE SCHEMA app_data;

CREATE TABLE IF NOT EXISTS app_data.orders
    AS
SELECT 
    DATE(o.order_ts) AS date,
    o.* ,
    cpg.* EXCLUDE (location_id, region, phone_number, country)
FROM tb_101.harmonized.orders_v o
JOIN tb_safegraph.public.frostbyte_tb_safegraph_s cpg
    ON o.location_id = cpg.location_id;

GRANT USAGE ON SCHEMA app_data TO SHARE IN APPLICATION PACKAGE {{package_name}};
GRANT SELECT ON VIEW orders TO SHARE IN APPLICATION PACKAGE {{package_name}};
