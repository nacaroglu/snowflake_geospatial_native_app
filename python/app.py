import snowflake.snowpark.functions as F
from snowflake.snowpark.types import StructType, StructField, IntegerType, DecimalType

def find_top_n_locations(session, top_n, city, my_longitude, my_latitude):
    # Define the schema for the output
    schema = StructType([
        StructField("location_id", IntegerType()),
        StructField("total_sales_usd", DecimalType()),
        StructField("geography_distance_miles", DecimalType()),
        StructField("geography_distance_kilometers", DecimalType())
    ])
    
    # Query to get the top N locations
    query = f"""
    WITH _top_n_locations AS (
        SELECT 
            location_id,
            ST_MAKEPOINT(longitude, latitude) AS geo_point,
            SUM(price) AS total_sales_usd
        FROM analytics.orders_v
        WHERE primary_city = '{city}'
        GROUP BY location_id, latitude, longitude
        ORDER BY total_sales_usd DESC
        LIMIT {top_n}
    )
    SELECT
        location_id, 
        total_sales_usd,
        ROUND(ST_DISTANCE(geo_point, ST_MAKEPOINT({my_longitude}, {my_latitude}))/1609, 2) AS geography_distance_miles,
        ROUND(ST_DISTANCE(geo_point, ST_MAKEPOINT({my_longitude}, {my_latitude}))/1000, 2) AS geography_distance_kilometers
    FROM _top_n_locations
    """
    
    # Execute the query and return the result
    return session.sql(query).collect()

# Register the UDTF
session.udtf.register(
    find_top_n_locations,
    output_schema=schema,
    name="find_top_n_locations",
    replace=True
)