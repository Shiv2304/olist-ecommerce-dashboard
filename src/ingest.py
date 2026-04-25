import os
from urllib.parse import quote_plus
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from urllib.parse import quote_plus
load_dotenv()

password = quote_plus(os.getenv('DB_PASSWORD'))
conn_str = (
    f"postgresql+psycopg2://{os.getenv('DB_USER')}:{password}"
    f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)
engine = create_engine(conn_str, echo=False)

FILES = {
    "olist_orders_dataset.csv": (
        "orders",
        ["order_purchase_timestamp", "order_approved_at",
         "order_delivered_carrier_date", "order_delivered_customer_date",
         "order_estimated_delivery_date"]
    ),
    "olist_order_items_dataset.csv":    ("order_items", ["shipping_limit_date"]),
    "olist_order_payments_dataset.csv": ("order_payments", []),
    "olist_order_reviews_dataset.csv":  ("order_reviews", ["review_creation_date", "review_answer_timestamp"]),
    "olist_products_dataset.csv":       ("products", []),
    "olist_sellers_dataset.csv":        ("sellers", []),
    "olist_customers_dataset.csv":      ("customers", []),
    "olist_geolocation_dataset.csv":    ("geolocation", []),
    "product_category_name_translation.csv": ("category_translation", []),
}

def load_csv(filepath, datetime_cols):
    df = pd.read_csv(filepath, low_memory=False)
    for col in datetime_cols:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce")
    str_cols = df.select_dtypes(include="object").columns
    df[str_cols] = df[str_cols].apply(lambda c: c.str.strip())
    return df

def ingest_all():
    for filename, (table, dt_cols) in FILES.items():
        filepath = os.path.join("data", filename)
        if not os.path.exists(filepath):
            print(f"  [SKIP] {filename} not found")
            continue
        print(f"  Loading {filename} → {table} ...", end=" ", flush=True)
        df = load_csv(filepath, dt_cols)
        df.to_sql(table, engine, if_exists="replace", index=False, chunksize=10_000, method="multi")
        print(f"{len(df):,} rows")

if __name__ == "__main__":
    print("Starting ingestion...\n")
    ingest_all()
    print("\nDone.")