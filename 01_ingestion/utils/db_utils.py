import os
from datetime import datetime
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")


def get_engine():
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT")
    db_name = os.getenv("DB_NAME")
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD")

    connection_url = URL.create(
        drivername="postgresql+psycopg2",
        username=db_user,
        password=db_password,
        host=db_host,
        port=db_port,
        database=db_name,
    )

    return create_engine(connection_url)


def clean_column_names(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = (
        df.columns
        .astype(str)
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
        .str.replace("-", "_", regex=False)
    )
    return df


def add_metadata(
    df: pd.DataFrame,
    source_file: str,
    source_platform: str,
    batch_id: str
) -> pd.DataFrame:
    df = df.copy()
    df["_source_file"] = source_file
    df["_source_platform"] = source_platform
    df["_ingested_at"] = datetime.now()
    df["_batch_id"] = batch_id
    return df


def load_to_bronze(
    df: pd.DataFrame,
    table_name: str,
    if_exists: str = "append"
) -> int:
    engine = get_engine()

    df = clean_column_names(df)

    # Bronze layer: store all original data as text to avoid type issues
    for col in df.columns:
        if col != "_ingested_at":
            df[col] = df[col].astype("string")

    df.to_sql(
        name=table_name,
        con=engine,
        schema="raw",
        if_exists=if_exists,
        index=False,
        method="multi",
        chunksize=1000,
    )

    return len(df)


def create_ingest_log_table():
    engine = get_engine()

    sql = """
    CREATE TABLE IF NOT EXISTS raw.ingest_log (
        log_id SERIAL PRIMARY KEY,
        batch_id TEXT,
        source_name TEXT,
        source_file TEXT,
        source_platform TEXT,
        rows_loaded INTEGER,
        status TEXT,
        error_message TEXT,
        started_at TIMESTAMP,
        finished_at TIMESTAMP,
        duration_sec NUMERIC
    );
    """

    with engine.begin() as conn:
        conn.execute(text(sql))

    print("raw.ingest_log table is ready.")