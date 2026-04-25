import os
import pandas as pd
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()

password = quote_plus(os.getenv('DB_PASSWORD'))
conn_str = (
    f"postgresql+psycopg2://{os.getenv('DB_USER')}:{password}"
    f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)
engine = create_engine(conn_str)

def run_query(sql_file):
    with open(sql_file, 'r') as f:
        query = f.read()
    return pd.read_sql(text(query), engine.connect())

# Q1
df_q1 = run_query('sql/q1_late_delivery.sql')
df_q1.to_csv('output/seller_late_delivery.csv', index=False)
print(f"Q1 exported: {len(df_q1)} rows")

# Q2
df_q2 = run_query('sql/q2_review_scores.sql')
df_q2.to_csv('output/category_review_scores.csv', index=False)
print(f"Q2 exported: {len(df_q2)} rows")

# Q3
df_q3 = run_query('sql/q3_regional_gaps.sql')
df_q3.to_csv('output/regional_gaps.csv', index=False)
print(f"Q3 exported: {len(df_q3)} rows")

# Q4
df_q4 = run_query('sql/q4_cancellation_trends.sql')
df_q4.to_csv('output/cancellation_trends.csv', index=False)
print(f"Q4 exported: {len(df_q4)} rows")

# Q5
df_q5 = run_query('sql/q5_seller_score.sql')
df_q5.to_csv('output/seller_composite_score.csv', index=False)
print(f"Q5 exported: {len(df_q5)} rows")