import duckdb

con = duckdb.connect("warehouse/analytics.duckdb")

con.execute("""
CREATE TABLE IF NOT EXISTS raw_users AS
SELECT * FROM read_csv_auto('data_generator/raw_users.csv');
""")

con.execute("""
CREATE TABLE IF NOT EXISTS raw_events AS 
SELECT * FROM read_csv_auto('data_generator/raw_events.csv');
""")

con.execute("""
CREATE TABLE IF NOT EXISTS raw_subscriptions AS
SELECT * FROM read_csv_auto('data_generator/raw_subscriptions.csv');
""")

con.close()
print("Raw tables loaded into DuckDB.")