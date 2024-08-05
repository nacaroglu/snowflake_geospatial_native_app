# Import python packages
import streamlit as st
from snowflake.snowpark import Session
#from snowflake.snowpark.context import get_active_session


# Write directly to the app
st.title("Geospatial App - Streamlit Edition")
st.write(
   """The following data is from the app that was created using Snowflake's Python UDFs.
   """
)

# Get the current credentials
session = Session.builder.getOrCreate()
#session = get_active_session()


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