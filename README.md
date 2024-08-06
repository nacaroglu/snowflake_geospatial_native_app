# AI Day Snowflake Geospatial Native App

## Overview

TODO: Add short description of LAB and What we are going to build today

## Prerequisites

- [ ]  [**Introduction to Tasty Bytes Quickstart**](https://quickstarts.snowflake.com/guide/tasty_bytes_introduction/index.html)
- [ ]  VSCode
- [ ]  [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index) and ACCOUNTADMIN role
- [ ]  [**tb_geospatial.sql**](https://github.com/Snowflake-Labs/sf-samples/blob/main/samples/tasty_bytes/FY25_Zero_To_Snowflake/tb_geospatial.sql?_fsi=ITns1Twe&_fsi=ITns1Twe)

## Creating Native App

### Create Application Files

You can create an application with following command

```bash
snow app init geospatial_native_app
Snowflake Native App project geospatial_native_app has been created at: geospatial_native_app
```

Here is the directory structure of created application 

![Untitled](AI%20Day%20Snowflake%20Geospatial%20Native%20App%209f9162b3f58b42ae864fba14483203a6/Untitled.png)

At this step three important files created for our application

- **Setup script:** An SQL script that runs automatically when a consumer installs an app in their account.
- **Manifest file:** A YAML file that contains basic configuration information about the app.
- **Project definition file:** A YAML file that contains information about the Snowflake objects that you want to create. ***snowflake.yml*** file

Change content of ***snowflake.yml*** file as follows: 

```bash

definition_version: 1
native_app:
   name: geospatial_native_app
   source_stage: stage_content.geospatial_native_app_stage
   artifacts:
      - src: app/*
        dest: ./
   package:
      name: geospatial_native_app_package
   application:
      name: geospatial_native_app
      debug: false
```

### Understanding Project Definition File

An application package is essentially a Snowflake database with added information about an app, acting as a container that includes:

- Shared data content
- Application files

To create an application package, your role needs the **`CREATE APPLICATION PACKAGE`** privilege. Grant this privilege using the Snowflake CLI with the command:

```sql
➜  snowflake snow sql -q 'GRANT CREATE APPLICATION PACKAGE ON ACCOUNT TO ROLE accountadmin' -c my_connection  
GRANT CREATE APPLICATION PACKAGE ON ACCOUNT TO ROLE accountadmin
+----------------------------------+
| status                           |
|----------------------------------|
| Statement executed successfully. |
+----------------------------------+
```

---

The **`snowflake.yml`** file defines the names of objects created in your Snowflake account:

- The application package (`geospatial_native_app_package`)
- The application object (`geospatial_native_app`) created from the package
- The stage for application files (`stage_content.geospatial_native_app_package)`

The stage name is schema-qualified and created within the application package. This stage stores files needed by the Snowflake Native App Framework, including those required by the app setup script or at runtime.

---

The **`artifacts`** section in the project definition file lists rules for copying files to the named stage. For example, files in the **`app/`** subfolder are copied to the stage’s root:

- **`tutorial/app/manifest.yml`** → **`@**geospatial_native_app_package**.stage_content.**geospatial_native_app_package`
- **`tutorial/app/README.md`** → **`@**geospatial_native_app_package**.stage_content.**geospatial_native_app_package`
- **`tutorial/app/setup_script.sql`** → **`@**geospatial_native_app_package**.stage_content.**geospatial_native_app_package`

### Developing ‘Hello’ Native App and Running

1. Add the following SQL statements at the end of the `setup_script.sql` file that you created in an earlier section of this tutorial:

```sql
CREATE APPLICATION ROLE IF NOT EXISTS app_public;
CREATE SCHEMA IF NOT EXISTS core;
GRANT USAGE ON SCHEMA core TO APPLICATION ROLE app_public;
```

1. Add the code for the stored procedure at the end of the `setup_script.sql` file:

```sql
CREATE OR REPLACE PROCEDURE CORE.HELLO_SNOWFLAKE()
  RETURNS STRING
  LANGUAGE SQL
  EXECUTE AS OWNER
  AS
  BEGIN
    RETURN 'Hello Snowflake Geospatial';
  END;
```

1. Add the following statement to the end of the `setup_script.sql` file:

```sql
GRANT USAGE ON PROCEDURE core.hello() TO APPLICATION ROLE app_public;
```

1. Create application package 

```sql
➜  geospatial_native_app snow app run -c my_connection

Checking if stage geospatial_native_app_package.stage_content.geospatial_native_app_stage exists, or creating a new one if none exists.
Performing a diff between the Snowflake stage and your local deploy_root ('/Users/ahmet.nacaroglu/Code/sandBox/snowflake/geospatial_native_app/output/deploy') directory.
Your stage is up-to-date with your local deploy root.
Validating Snowflake Native App setup script.
Creating new application object geospatial_native_app in account.
Your application object (geospatial_native_app) is now available:
https://app.snowflake.com/YRJXOSO/my_entrprise_account/#/apps/application/GEOSPATIAL_NATIVE_APP
```

This command performs the following tasks:

- Create an application package name `hello_snowflake_package` with schema `stage_content` and stage `hello_snowflake_stage`.
- Upload all required files to the named stage.
- Create or upgrade the app `hello_snowflake_app` using files from this stage.

1. Run Stored procedure:  If the command executes without issues, it will display a URL. This URL allows you to view your application in Snowsight. To execute the HELLO_SNOWFLAKE stored procedure previously added to `setup_script.sql`, use the following Snowflake CLI command.

```sql
➜  geospatial_native_app snow sql -q "call geospatial_native_app.core.hello_snowflake()" -c my_connection  

call geospatial_native_app.core.hello_snowflake()
+----------------------------+
| HELLO_SNOWFLAKE            |
|----------------------------|
| Hello Snowflake Geospatial |
+----------------------------+
```

## Adding Geospatial Analysis To Native App

### Integrate Data Content with App

1. Download tb_101 → https://quickstarts.snowflake.com/guide/tasty_bytes_introduction/index.html#1
2. Download initial POI data and execute first 2 steps → https://github.com/Snowflake-Labs/sf-samples/blob/main/samples/tasty_bytes/FY25_Zero_To_Snowflake/tb_geospatial.sql?_fsi=ITns1Twe&_fsi=ITns1Twe&_fsi=ITns1Twe&_fsi=ITns1Twe&_fsi=ITns1Twe&_fsi=ITns1Twe 

1. **Create a table to share with an app**
    1. create a folder `scripts`, then a file `app_content.sql` inside the folder. Add the following contents to this file:

```sql
USE APPLICATION PACKAGE {{package_name}};

CREATE SCHEMA IF NOT EXISTS app_data;
USE SCHEMA app_data;
CREATE OR REPLACE TABLE app_data.orders
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
```

ii. Add an entry to the project definition file to ensure that this script runs when you update your application package. The final project definition file should be:Test App with Data Content

```sql
definition_version: 1
native_app:
   name: geospatial_native_app
   source_stage: stage_content.geospatial_native_app_stage
   artifacts:
      - src: app/*
        dest: ./
   package:
      name: geospatial_native_app_package
      scripts:
         - scripts/app_content.sql
   application:
      name: geospatial_native_app
      debug: false
```

**Add a view to access data content**

To add a view to access data content:

1. To create a schema for the view, add the following to the setup script:

These statements create a versioned schema to contain the view and grant the USAGE privilege on the schema. The Snowflake Native App Framework uses versioned schema to handle different versions of stored procedures and functions.

```sql
CREATE OR ALTER VERSIONED SCHEMA code_schema;
GRANT USAGE ON SCHEMA code_schema  TO APPLICATION ROLE app_public;
```

1. To create the view, add the following to the setup script:

```sql
CREATE VIEW IF NOT EXISTS code_schema orders_v
  AS SELECT FROM app_data.orders;

GRANT SELECT ON VIEW code_schema.orders_v TO APPLICATION ROLE app_public;
```

These statements create the view in the `code_schema` schema and grant the required privilege on the view to the application role.

This updated setup script is also uploaded to the stage the next time you deploy your app using Snowflake CLI.

**Test the updated app**

1. To update the application package and the application object installed in the consumer account, run the following command:

```sql
snow app run -c connection_name
```

where `connection_name` is the name of the connection you specified in the `config.toml` file when you installed the Snowflake CLI.

This uploads all the edited files to the stage, runs the `scripts/app_content.sql` script, and upgrade the app using those files on the stage.

```sql
➜  geospatial_native_app snow app run -c my_connection                                                         
Applying package script: scripts/app_content.sql
Checking if stage geospatial_native_app_package.stage_content.geospatial_native_app_stage exists, or creating a new one if none exists.
Performing a diff between the Snowflake stage and your local deploy_root ('/Users/ahmet.nacaroglu/Code/sandBox/snowflake/geospatial_native_app/output/deploy') directory.
Your stage is up-to-date with your local deploy root.
Validating Snowflake Native App setup script.
Upgrading existing application object geospatial_native_app.
Your application object (geospatial_native_app) is now available:
https://app.snowflake.com/YRJXOSO/my_entrprise_account/#/apps/application/GEOSPATIAL_NATIVE_APP
```

1. To verify that the view works correctly, run the following command:

```sql
 geospatial_native_app snow sql -q "select DATE, ORDER_ID, TRUCK_ID, MENU_TYPE, 
 PRIMARY_CITY, ORDER_AMOUNT from geospatial_native_app.code_schema.orders_v where 
 primary_city = 'London'  limit 10" -c my_connection
 
select DATE, ORDER_ID, TRUCK_ID, MENU_TYPE, PRIMARY_CITY, ORDER_AMOUNT from geospatial_native_app.code_schema.orders_v where primary_city = 'London'  limit 10
+----------------------------------------------------------------------------+
| DATE       | ORDER_ID | TRUCK_ID | MENU_TYPE | PRIMARY_CITY | ORDER_AMOUNT |
|------------+----------+----------+-----------+--------------+--------------|
| 2020-12-11 | 33831172 | 122      | BBQ       | London       | 74.0000      |
| 2020-12-11 | 33831172 | 122      | BBQ       | London       | 74.0000      |
| 2020-12-11 | 33831172 | 122      | BBQ       | London       | 74.0000      |
| 2020-12-11 | 33831172 | 122      | BBQ       | London       | 74.0000      |
| 2020-12-11 | 33831172 | 122      | BBQ       | London       | 74.0000      |
| 2020-12-11 | 33831172 | 122      | BBQ       | London       | 74.0000      |
| 2020-12-11 | 33834996 | 131      | Poutine   | London       | 101.0000     |
| 2020-12-11 | 33834996 | 131      | Poutine   | London       | 101.0000     |
| 2020-12-11 | 33834996 | 131      | Poutine   | London       | 101.0000     |
| 2020-12-11 | 33834996 | 131      | Poutine   | London       | 101.0000     |
+----------------------------------------------------------------------------+
```

### Develop Application Logic With Plain SQL

1. Find  Top N sales point for location (city)

```sql
USE database tb_101;
USE ROLE tb_data_engineer;

-- set variables
SET top_n=10;
SET location='Paris';

SELECT 
    location_id,
    ST_MAKEPOINT(longitude, latitude) AS geo_point,
    SUM(price) AS total_sales_usd
FROM analytics.orders_v
WHERE primary_city = $location
GROUP BY location_id, latitude, longitude
ORDER BY total_sales_usd DESC
Limit $top_n
```

1. Find distances from selected location

```sql
USE database tb_101;
USE ROLE tb_data_engineer;

-- find list of possible cities
SELECT distinct city FROM tb_safegraph.public.frostbyte_tb_safegraph_s cpg

-- set variables
SET top_n=10;
SET location='Boston';

SELECT 
    location_id,
    ST_MAKEPOINT(longitude, latitude) AS geo_point,
    SUM(price) AS total_sales_usd
FROM analytics.orders_v
WHERE primary_city = $location
GROUP BY location_id, latitude, longitude
ORDER BY total_sales_usd DESC
Limit $top_n

-- Top selling location in Boston
set my_longtidute = -7.103682400000000e+01;
set my_latidute = 4.237096700000000e+01;

-- This query having error. Any suggestions?
set my_geo_point = (select ST_MAKEPOINT($my_longtidute, $my_latidute));

WITH _top_n_locations AS
(
        SELECT 
        location_id,
        ST_MAKEPOINT(longitude, latitude) AS geo_point,
        SUM(price) AS total_sales_usd
    FROM analytics.orders_v
    WHERE primary_city = $location
    GROUP BY location_id, latitude, longitude
    ORDER BY total_sales_usd DESC
    Limit $top_n
)
SELECT
    a.location_id,    
    ROUND(ST_DISTANCE(a.geo_point, ST_MAKEPOINT($my_longtidute, $my_latidute))/1609,2) AS geography_distance_miles,
    ROUND(ST_DISTANCE(a.geo_point, ST_MAKEPOINT($my_longtidute, $my_latidute))/1000,2) AS geography_distance_kilometers
FROM _top_n_locations a
```

![Untitled](AI%20Day%20Snowflake%20Geospatial%20Native%20App%209f9162b3f58b42ae864fba14483203a6/Untitled%201.png)

Result of the above query. Top selling location is test point  🙂

### Embed Application Logic to Native App

1. Add following function creation and permission granting scripts to setup file

```sql
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
```

1. Install  application

```sql
snow app run -c my_connection 

Applying package script: scripts/app_content.sql
Checking if stage geospatial_native_app_package.stage_content.geospatial_native_app_stage exists, or creating a new one if none exists.
Performing a diff between the Snowflake stage and your local deploy_root ('/Users/ahmet.nacaroglu/Code/sandBox/snowflake/geospatial_native_app/output/deploy') directory.
Local changes to be deployed:
  modified: app/setup_script.sql -> setup_script.sql
Updating the Snowflake stage from your local /Users/ahmet.nacaroglu/Code/sandBox/snowflake/geospatial_native_app/output/deploy directory.
Validating Snowflake Native App setup script.
Upgrading existing application object geospatial_native_app.
Your application object (geospatial_native_app) is now available:
https://app.snowflake.com/YRJXOSO/my_entrprise_account/#/apps/application/GEOSPATIAL_NATIVE_APP
```

1. Test application

```sql
snow sql -q "select * from table (geospatial_native_app.code_schema.find_top_locations('Boston', 10, -7.103682400000000e+01, 4.237096700000000e+01 ))" -c my_connection 

```

Result would be like

```sql
+----------------------------------------------------------------------+
| LOCATION_ID | TOTAL_SALES_USD | DISTANCE_MILES | DISTANCE_KILOMETERS |
|-------------+-----------------+----------------+---------------------|
| 5251.00     | 542621.25       | 0.0            | 0.0                 |
| 13099.00    | 528727.75       | 1.59           | 2.56                |
| 3766.00     | 519837.00       | 3.98           | 6.41                |
| 3424.00     | 519256.50       | 1.39           | 2.23                |
| 15265.00    | 516328.00       | 5.27           | 8.48                |
| 1402.00     | 505144.75       | 1.03           | 1.66                |
| 15326.00    | 504467.75       | 1.35           | 2.18                |
| 10900.00    | 504054.75       | 1.28           | 2.07                |
| 3482.00     | 497800.00       | 1.54           | 2.48                |
| 1368.00     | 496002.25       | 2.46           | 3.96                |
+----------------------------------------------------------------------+
```

### Develop Application Logic in Python?

## Streamlit Integration

### Add Streamlit Integration

**Create the streamlit app file**

1. In the `geospatial_native_app` folder, create a subfolder named `streamlit`.
2. In the `streamlit` folder, create a file named `geospatial_app.py`
3. Add the following code to this file:
4. 

```sql
# Import python packages
import streamlit as st
from snowflake.snowpark import Session

# Write directly to the app
st.title("Geospatial App - Streamlit Edition")
st.write(
   """The following data is from the app that was created using Snowflake's Python UDFs.
   """
)

# Get the current credentials
session = Session.builder.getOrCreate()

#  Create an example data frame
data_frame = session.sql("""
                         select * from table 
                         (geospatial_native_app.code_schema.find_top_locations('Boston', 10, -7.103682400000000e+01, 4.237096700000000e+01 ))
                        """
                    )

# Execute the query and convert it into a Pandas data frame
queried_data = data_frame.to_pandas()

# Display the Pandas data frame as a Streamlit data frame.
st.dataframe(queried_data, use_container_width=True)
```

1. Add the following to the existing `artifacts` section of the project definition file:
2. 

```sql
- streamlit/geospatial_app.py
```

### **Add the streamlit object to the setup script**

To create the Streamlit object in the app, do the following:

1. Add the following statement at the end of the `setup_script.sql` file to create the Streamlit object:
    
    ```sql
    CREATE STREAMLIT IF NOT EXISTS code_schema.geospatial_app_streamlit
      FROM '/streamlit'
      MAIN_FILE = '/geospatial_app.py'
    ;
    ```
    
    This statement creates a STREAMLIT object in the core schema.
    
2. Add the following statement at the end of the `setup_script.sql` file to allow the APP_PUBLIC role to access the Streamlit object:
    
    ```sql
    GRANT USAGE ON STREAMLIT code_schema.geospatial_app_streamlit TO APPLICATION ROLE app_public;
    ```
    

**Install the updated app**

To update the application package and the app, run the following command:

```sql
geospatial_native_app snow app run -c my_connection

Applying package script: scripts/app_content.sql
Checking if stage geospatial_native_app_package.stage_content.geospatial_native_app_stage exists, or creating a new one if none exists.
Performing a diff between the Snowflake stage and your local deploy_root ('/Users/ahmet.nacaroglu/Code/sandBox/snowflake/geospatial_native_app/output/deploy') directory.
Local changes to be deployed:
  modified: streamlit/geospatial_app.py -> streamlit/geospatial_app.py
Updating the Snowflake stage from your local /Users/ahmet.nacaroglu/Code/sandBox/snowflake/geospatial_native_app/output/deploy directory.
Validating Snowflake Native App setup script.
Upgrading existing application object geospatial_native_app.
Your application object (geospatial_native_app) is now available:
https://app.snowflake.com/YRJXOSO/my_entrprise_account/#/apps/application/GEOSPATIAL_NATIVE_APP
```

### Integrate with Map Component (Folium)

## Testing and Versioning

### Create a Version the Application

### Test on Snowsight

## Publishing and Installation

## References

- https://docs.snowflake.com/en/developer-guide/native-apps/tutorials/getting-started-tutorial#introduction
- https://quickstarts.snowflake.com/guide/getting_started_with_native_apps/#0
- https://quickstarts.snowflake.com/guide/tasty_bytes_zero_to_snowflake_geospatial/#0
- 
-
