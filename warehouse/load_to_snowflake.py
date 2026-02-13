import snowflake.connector
import pandas as pd
from datetime import datetime
import os
from dotenv import load_dotenv 

load_dotenv()


SNOWFLAKE_CONFIG = {
    "user": os.getenv("SNOWFLAKE_USER"),
    "password": os.getenv("SNOWFLAKE_PASSWORD"),
    "account": os.getenv("SNOWFLAKE_ACCOUNT"),
    "warehouse": "ANALYTICS_WH",
    "database": "RAW",
    "schema": "PUBLIC",
}

conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
cs = conn.cursor()

def load_csv(table_name, csv_path):
    df = pd.read_csv(csv_path)
    df["loaded_at"] =  datetime.utcnow()

    success, nchunks, nrows, _ =  cs.write_pandas(
        conn, 
        df,
        table_name,
        auto_create_table=True
    )
    print(f"{table_name}: {nrows} rows loaded")

    load_csv("RAW_USERS", "raw_users.csv")
    load_csv("RAW_EVENTS", "raw_events.csv")
    load_csv("RAW_SUBSCRIPTIONS", "raw_subscriptions.csv")

    cs.close()
    conn.close()