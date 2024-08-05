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


CREATE or REPLACE FUNCTION code_schema.find_top_n_locations(
    top_n INT,
    city VARCHAR,
    my_longtidute DECIMAL,
    my_latidute DECIMAL)
  RETURNS INT
  LANGUAGE PYTHON
  RUNTIME_VERSION=3.8
  PACKAGES = ('snowflake.snowpark.functions', 'snowflake.snowpark.types')
  IMPORTS = ('/python/app.py')
  HANDLER='app.find_top_n_locations';

-- Granting permissions
GRANT USAGE ON FUNCTION code_schema.find_top_n_locations(INT, VARCHAR, DECIMAL, DECIMAL) TO APPLICATION ROLE app_public;



