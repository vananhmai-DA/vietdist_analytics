import sys
import time
import uuid
from pathlib import Path
from datetime import datetime


# Add 01_ingestion folder to Python path
sys.path.append(str(Path(__file__).resolve().parents[1]))

from utils.file_parser import parse_file
from utils.db_utils import (
    add_metadata,
    load_to_bronze,
    create_ingest_log_table,
    write_ingest_log,
    validate_bronze_load,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]

SOURCE_FILE = PROJECT_ROOT / "data" / "raw" / "SRC05_distributor_orders.xlsx"
TABLE_NAME = "distributor_orders"
SOURCE_PLATFORM = "local"


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

        current_step = "PARSE_FILE"
        df = parse_file(SOURCE_FILE)

        if df.empty:
            raise ValueError(f"Source file is empty: {SOURCE_FILE.name}")

        print(f"Raw shape: {df.shape[0]} rows x {df.shape[1]} columns")

        current_step = "ADD_METADATA"
        df = add_metadata(
            df=df,
            source_file=SOURCE_FILE.name,
            source_platform=SOURCE_PLATFORM,
            batch_id=batch_id,
        )

        current_step = "LOAD_TO_BRONZE"
        rows_loaded = load_to_bronze(
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