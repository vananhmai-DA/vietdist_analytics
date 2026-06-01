import sys
import time
import uuid
from pathlib import Path
from datetime import datetime

import pandas as pd


# Add 01_ingestion folder to Python path
sys.path.append(str(Path(__file__).resolve().parents[1]))

from utils.db_utils import (
    add_metadata,
    load_to_bronze_safe,
    create_ingest_log_table,
    write_ingest_log,
    validate_bronze_load,
    clean_column_names,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]

SOURCE_FILE = PROJECT_ROOT / "data" / "raw" / "SRC02_sales_target_plan.xlsx"
TABLE_NAME = "sales_target_plan"
SOURCE_PLATFORM = "local"


def infer_version_label(file_name: str, sheet_name: str) -> str:
    """
    Infer target version from file name or sheet name.
    This is a Bronze-level helper only.
    Silver layer will handle official versioning logic later.
    """

    text = f"{file_name}_{sheet_name}".lower()

    if "v3" in text:
        return "v3"
    if "v2" in text:
        return "v2"
    if "v1" in text:
        return "v1"

    return "unknown"


def read_all_target_sheets(file_path: Path) -> pd.DataFrame:
    """
    Read all sheets from sales target plan file.
    Each sheet may represent a different version or target structure.
    """

    all_sheets = pd.read_excel(
        file_path,
        sheet_name=None,
        dtype=str
    )

    frames = []

    for sheet_name, df in all_sheets.items():
        if df.empty:
            continue

        df = df.copy()
        df = clean_column_names(df)

        df["_sheet_name"] = sheet_name
        df["_version_label"] = infer_version_label(file_path.name, sheet_name)

        frames.append(df)

    if not frames:
        return pd.DataFrame()

    return pd.concat(frames, ignore_index=True, sort=False)


def run():
    batch_id = str(uuid.uuid4())
    started_at = datetime.now()
    start_time = time.time()

    rows_loaded = 0
    current_step = "START"

    try:
        current_step = "CREATE_INGEST_LOG_TABLE"
        create_ingest_log_table()

        current_step = "CHECK_SOURCE_FILE"
        print(f"Reading file: {SOURCE_FILE}")

        if not SOURCE_FILE.exists():
            raise FileNotFoundError(f"Source file not found: {SOURCE_FILE}")

        current_step = "PARSE_ALL_TARGET_SHEETS"
        df = read_all_target_sheets(SOURCE_FILE)

        if df.empty:
            raise ValueError(f"Source file is empty or all sheets are empty: {SOURCE_FILE.name}")

        print(f"Raw shape: {df.shape[0]} rows x {df.shape[1]} columns")
        print(f"Sheets loaded: {df['_sheet_name'].nunique()}")
        print(f"Versions detected: {df['_version_label'].unique().tolist()}")

        current_step = "ADD_METADATA"
        df = add_metadata(
            df=df,
            source_file=SOURCE_FILE.name,
            source_platform=SOURCE_PLATFORM,
            batch_id=batch_id,
        )

        current_step = "LOAD_TO_BRONZE"
        rows_loaded = load_to_bronze_safe(
            df=df,
            table_name=TABLE_NAME,
            if_exists="append",
        )

        current_step = "VALIDATE_LOAD"
        is_valid = validate_bronze_load(
            table_name=TABLE_NAME,
            batch_id=batch_id,
            expected_rows=rows_loaded,
        )

        if not is_valid:
            raise ValueError(
                f"Validation failed for raw.{TABLE_NAME}. "
                f"Expected {rows_loaded} rows for batch_id {batch_id}."
            )

        finished_at = datetime.now()
        duration_sec = round(time.time() - start_time, 2)

        current_step = "WRITE_SUCCESS_LOG"
        write_ingest_log(
            batch_id=batch_id,
            source_name=TABLE_NAME,
            source_file=SOURCE_FILE.name,
            source_platform=SOURCE_PLATFORM,
            rows_loaded=rows_loaded,
            status="SUCCESS",
            error_message=None,
            failed_step=None,
            started_at=started_at,
            finished_at=finished_at,
            duration_sec=duration_sec,
        )

        print(f"SUCCESS: loaded and validated {rows_loaded} rows into raw.{TABLE_NAME}")
        print(f"Batch ID: {batch_id}")

    except Exception as e:
        finished_at = datetime.now()
        duration_sec = round(time.time() - start_time, 2)

        write_ingest_log(
            batch_id=batch_id,
            source_name=TABLE_NAME,
            source_file=SOURCE_FILE.name,
            source_platform=SOURCE_PLATFORM,
            rows_loaded=rows_loaded,
            status="FAILED",
            error_message=str(e),
            failed_step=current_step,
            started_at=started_at,
            finished_at=finished_at,
            duration_sec=duration_sec,
        )

        print("FAILED")
        print(f"Failed step: {current_step}")
        print(e)


if __name__ == "__main__":
    run()