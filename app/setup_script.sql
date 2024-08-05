CREATE APPLICATION ROLE IF NOT EXISTS app_public;
CREATE SCHEMA IF NOT EXISTS core;
GRANT USAGE ON SCHEMA core TO APPLICATION ROLE app_public;

CREATE OR REPLACE PROCEDURE CORE.HELLO_SNOWFLAKE()
  RETURNS STRING
  LANGUAGE SQL
  EXECUTE AS OWNER
  AS
  BEGIN
    RETURN 'Hello Snowflake Geospatial';
  END;

GRANT USAGE ON PROCEDURE core.HELLO_SNOWFLAKE() TO APPLICATION ROLE app_public;

CREATE OR ALTER VERSIONED SCHEMA code_schema;
GRANT USAGE ON SCHEMA code_schema  TO APPLICATION ROLE app_public;

CREATE VIEW IF NOT EXISTS code_schema.orders_v
  AS SELECT * FROM app_data.orders;

GRANT SELECT ON VIEW code_schema.orders_v TO APPLICATION ROLE app_public;


CREATE OR REPLACE FUNCTION code_schema.find_top_locations(
  city varchar, 
  topn number, 
  my_longtidute number(8,6), 
  my_latidute number(8,6)
)
RETURNS TABLE(
    location_id numeric(11, 2), 
    total_sales_usd numeric(10,2), 
    distance_miles float, 
    distance_kilometers float   
)
LANGUAGE SQL
AS 
  $$
    SELECT 
        location_id, 
        total_sales_usd, 
        ROUND(ST_DISTANCE(geo_point, ST_MAKEPOINT(my_longtidute, my_latidute))/1609,2) AS distance_miles,
        ROUND(ST_DISTANCE(geo_point, ST_MAKEPOINT(my_longtidute, my_latidute))/1000,2) AS distance_kilometers       
    FROM (    
        SELECT         
            location_id,
            SUM(price) AS total_sales_usd,
            ST_MAKEPOINT(longitude, latitude) AS geo_point,
            ROW_NUMBER() OVER (ORDER BY total_sales_usd DESC) AS row_number
        FROM code_schema.orders_v 
        WHERE primary_city = city
        GROUP BY location_id, latitude, longitude        
    ) WHERE row_number<=topn
    
  $$
  ;
  
-- Granting permissions
GRANT USAGE ON FUNCTION code_schema.find_top_locations(varchar, number, number(8,6), number(8,6)) TO APPLICATION ROLE app_public;

CREATE STREAMLIT IF NOT EXISTS code_schema.geospatial_app_streamlit
  FROM '/streamlit'
  MAIN_FILE = '/geospatial_app.py'
;

GRANT USAGE ON STREAMLIT code_schema.geospatial_app_streamlit TO APPLICATION ROLE app_public;


GRANT USAGE ON SCHEMA code_schema TO APPLICATION ROLE app_public;
GRANT CREATE STREAMLIT ON SCHEMA code_schema TO APPLICATION ROLE app_public;
GRANT CREATE STAGE ON SCHEMA code_schema TO APPLICATION ROLE app_public;

-- Don't forget to grant USAGE on a warehouse (if you can).
--GRANT USAGE ON WAREHOUSE compute_wh TO APPLICATION ROLE app_public;
