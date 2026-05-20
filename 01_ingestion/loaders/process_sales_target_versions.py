import re
import sys
import time
import uuid
from pathlib import Path
from datetime import datetime

import pandas as pd
from sqlalchemy import text

# Add 01_ingestion folder to Python path
sys.path.append(str(Path(__file__).resolve().parents[1]))

from utils.db_utils import get_engine, clean_column_names


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_FILE = PROJECT_ROOT / "data" / "raw" / "SRC02_sales_target_plan.xlsx"
SOURCE_PLATFORM = "local"

TARGET_FILES_TABLE = "sales_target_files"
TARGET_RAW_TABLE = "sales_targets_raw"

SKIP_SHEETS = {"summary"}


def extract_version_label(sheet_name: str) -> str:
    """
    Extract version label from sheet name.
    Examples:
    - Plan_v1_Original -> v1
    - Plan_v2_Adjustment_H2 -> v2
    """
    match = re.search(r"(v\d+)", sheet_name.lower())
    if match:
        return match.group(1)

    raise ValueError(f"Cannot extract version label from sheet name: {sheet_name}")


def create_target_tables():
    engine = get_engine()

    sql = """
    CREATE TABLE IF NOT EXISTS raw.sales_target_files (
        file_id SERIAL PRIMARY KEY,
        batch_id TEXT,
        source_file TEXT,
        sheet_name TEXT,
        version_label TEXT,
        rows_loaded INTEGER,
        status TEXT,
        error_message TEXT,
        ingested_at TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS raw.sales_targets_raw (
        version_label TEXT,
        version_date TEXT,
        effective_from TEXT,
        effective_to TEXT,
        employee_id TEXT,
        employee_name TEXT,
        region TEXT,
        team TEXT,
        year TEXT,
        month TEXT,
        month_col TEXT,
        target_revenue TEXT,
        target_quantity TEXT,
        target_new_customers TEXT,
        sheet_name TEXT,
        _source_file TEXT,
        _source_platform TEXT,
        _ingested_at TIMESTAMP,
        _batch_id TEXT
    );
    """

    with engine.begin() as conn:
        conn.execute(text(sql))

    print("raw.sales_target_files and raw.sales_targets_raw are ready.")


def normalize_target_sheet(df: pd.DataFrame, sheet_name: str, batch_id: str) -> pd.DataFrame:
    """
    Normalize one sales target sheet into long raw format.

    Current sample sheets are already in long format with a month column.
    This function still standardizes month_col to T1..T12 and removes any Total/Tổng rows.
    """
    version_label = extract_version_label(sheet_name)

    df = clean_column_names(df)

    # Drop fully empty rows
    df = df.dropna(how="all").copy()

    # Ensure expected columns exist
    expected_cols = [
        "plan_version",
        "version_date",
        "effective_from",
        "effective_to",
        "employee_id",
        "employee_name",
        "region",
        "team",
        "year",
        "month",
        "target_revenue",
        "target_quantity",
        "target_new_customers",
    ]

    for col in expected_cols:
        if col not in df.columns:
            df[col] = None

    # Remove rows containing Tổng/Total in key fields
    for col in ["employee_id", "employee_name", "month"]:
        df[col] = df[col].astype("string")

    invalid_total_mask = (
        df["employee_id"].str.lower().str.contains("tổng|total", na=False)
        | df["employee_name"].str.lower().str.contains("tổng|total", na=False)
        | df["month"].str.lower().str.contains("tổng|total", na=False)
    )

    df = df.loc[~invalid_total_mask].copy()

    # Standardize version label from sheet name
    df["version_label"] = version_label

    # Convert month into month_col T1..T12
    month_num = pd.to_numeric(df["month"], errors="coerce")
    df["month_col"] = month_num.apply(
        lambda x: f"T{int(x)}" if pd.notna(x) and 1 <= int(x) <= 12 else None
    )

    # Keep only valid months T1..T12
    df = df[df["month_col"].notna()].copy()

    # Metadata
    df["sheet_name"] = sheet_name
    df["_source_file"] = SOURCE_FILE.name
    df["_source_platform"] = SOURCE_PLATFORM
    df["_ingested_at"] = datetime.now()
    df["_batch_id"] = batch_id

    # Rename plan_version to version_label logic already handled
    # Keep version_date / effective fields from original data
    output_cols = [
        "version_label",
        "version_date",
        "effective_from",
        "effective_to",
        "employee_id",
        "employee_name",
        "region",
        "team",
        "year",
        "month",
        "month_col",
        "target_revenue",
        "target_quantity",
        "target_new_customers",
        "sheet_name",
        "_source_file",
        "_source_platform",
        "_ingested_at",
        "_batch_id",
    ]

    df = df[output_cols].copy()

    # Store Bronze values as text except timestamp
    for col in df.columns:
        if col != "_ingested_at":
            df[col] = df[col].astype("string")

    return df


def load_sales_target_versions():
    engine = get_engine()
    batch_id = str(uuid.uuid4())

    create_target_tables()

    all_sheets = pd.read_excel(SOURCE_FILE, sheet_name=None, engine="openpyxl")

    target_sheets = {
        sheet_name: df
        for sheet_name, df in all_sheets.items()
        if sheet_name.lower() not in SKIP_SHEETS
    }

    print(f"Found {len(target_sheets)} target sheet(s): {list(target_sheets.keys())}")

    for sheet_name, df in target_sheets.items():
        started = time.time()
        status = "SUCCESS"
        error_message = None
        rows_loaded = 0

        try:
            print("\n" + "=" * 80)
            print(f"Processing sheet: {sheet_name}")

            normalized_df = normalize_target_sheet(
                df=df,
                sheet_name=sheet_name,
                batch_id=batch_id,
            )

            rows_loaded = len(normalized_df)

            with engine.begin() as conn:
                # Idempotent reload for the same file + sheet.
                # This prevents duplicates when rerunning the script,
                # but does not delete other versions/sheets.
                conn.execute(
                    text("""
                        DELETE FROM raw.sales_targets_raw
                        WHERE _source_file = :source_file
                          AND sheet_name = :sheet_name;
                    """),
                    {
                        "source_file": SOURCE_FILE.name,
                        "sheet_name": sheet_name,
                    },
                )

                conn.execute(
                    text("""
                        DELETE FROM raw.sales_target_files
                        WHERE source_file = :source_file
                          AND sheet_name = :sheet_name;
                    """),
                    {
                        "source_file": SOURCE_FILE.name,
                        "sheet_name": sheet_name,
                    },
                )

            normalized_df.to_sql(
                name=TARGET_RAW_TABLE,
                con=engine,
                schema="raw",
                if_exists="append",
                index=False,
                method="multi",
                chunksize=1000,
            )

            version_label = extract_version_label(sheet_name)

            with engine.begin() as conn:
                conn.execute(
                    text("""
                        INSERT INTO raw.sales_target_files (
                            batch_id,
                            source_file,
                            sheet_name,
                            version_label,
                            rows_loaded,
                            status,
                            error_message,
                            ingested_at
                        )
                        VALUES (
                            :batch_id,
                            :source_file,
                            :sheet_name,
                            :version_label,
                            :rows_loaded,
                            :status,
                            :error_message,
                            :ingested_at
                        );
                    """),
                    {
                        "batch_id": batch_id,
                        "source_file": SOURCE_FILE.name,
                        "sheet_name": sheet_name,
                        "version_label": version_label,
                        "rows_loaded": rows_loaded,
                        "status": status,
                        "error_message": error_message,
                        "ingested_at": datetime.now(),
                    },
                )

            print(f"SUCCESS: loaded {rows_loaded} rows from {sheet_name}")

        except Exception as e:
            status = "FAILED"
            error_message = str(e)

            with engine.begin() as conn:
                conn.execute(
                    text("""
                        INSERT INTO raw.sales_target_files (
                            batch_id,
                            source_file,
                            sheet_name,
                            version_label,
                            rows_loaded,
                            status,
                            error_message,
                            ingested_at
                        )
                        VALUES (
                            :batch_id,
                            :source_file,
                            :sheet_name,
                            :version_label,
                            :rows_loaded,
                            :status,
                            :error_message,
                            :ingested_at
                        );
                    """),
                    {
                        "batch_id": batch_id,
                        "source_file": SOURCE_FILE.name,
                        "sheet_name": sheet_name,
                        "version_label": extract_version_label(sheet_name),
                        "rows_loaded": 0,
                        "status": status,
                        "error_message": error_message,
                        "ingested_at": datetime.now(),
                    },
                )

            print(f"FAILED: {sheet_name}")
            print(error_message)

        print(f"Duration: {round(time.time() - started, 2)} sec")


def refresh_sales_target_versions_summary():
    engine = get_engine()

    sql = """
    DROP TABLE IF EXISTS raw.sales_target_versions;

    CREATE TABLE raw.sales_target_versions AS
    SELECT
        version_label,
        MIN(_source_file) AS source_file,
        MIN(sheet_name) AS sheet_name,
        COUNT(*) AS row_count,
        COUNT(DISTINCT employee_id) AS employee_count,
        COUNT(DISTINCT month_col) AS month_count,
        MIN(month_col) AS min_month_col,
        MAX(month_col) AS max_month_col,
        MIN(_ingested_at) AS first_ingested_at,
        MAX(_ingested_at) AS last_ingested_at
    FROM raw.sales_targets_raw
    GROUP BY version_label
    ORDER BY version_label;
    """

    with engine.begin() as conn:
        conn.execute(text(sql))

    print("\nraw.sales_target_versions summary table is ready.")


def validate_results():
    engine = get_engine()

    with engine.connect() as conn:
        print("\nDistinct versions from raw.sales_target_files")
        print("=" * 80)

        versions = conn.execute(
            text("""
                SELECT DISTINCT version_label
                FROM raw.sales_target_files
                ORDER BY version_label;
            """)
        )

        for row in versions:
            print("-", row.version_label)

        print("\nRows per version in raw.sales_targets_raw")
        print("=" * 80)

        rows = conn.execute(
            text("""
                SELECT version_label, COUNT(*) AS row_count
                FROM raw.sales_targets_raw
                GROUP BY version_label
                ORDER BY version_label;
            """)
        )

        for row in rows:
            print(f"{row.version_label}: {row.row_count} rows")

        print("\nCheck invalid total rows")
        print("=" * 80)

        total_rows = conn.execute(
            text("""
                SELECT COUNT(*)
                FROM raw.sales_targets_raw
                WHERE
                    LOWER(COALESCE(employee_id, '')) LIKE '%tổng%'
                    OR LOWER(COALESCE(employee_name, '')) LIKE '%tổng%'
                    OR LOWER(COALESCE(month_col, '')) LIKE '%tổng%'
                    OR LOWER(COALESCE(month_col, '')) LIKE '%total%';
            """)
        ).scalar()

        print(f"Rows containing 'TỔNG' or 'Total': {total_rows}")

        print("\nMonth values")
        print("=" * 80)

        months = conn.execute(
            text("""
                SELECT DISTINCT month_col
                FROM raw.sales_targets_raw
                ORDER BY month_col;
            """)
        )

        for row in months:
            print("-", row.month_col)


if __name__ == "__main__":
    load_sales_target_versions()
    refresh_sales_target_versions_summary()
    validate_results()