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

SOURCE_FOLDER = PROJECT_ROOT / "data" / "raw"
FILE_PATTERN = "SRC09_return_transactions*.csv"

TABLE_NAME = "return_transactions"
SOURCE_PLATFORM = "local"


def load_one_file(source_file: Path) -> int:
    batch_id = str(uuid.uuid4())
    started_at = datetime.now()
    start_time = time.time()

    rows_loaded = 0
    current_step = "START"

    try:
        current_step = "CHECK_SOURCE_FILE"
        print("-" * 80)
        print(f"Reading file: {source_file}")

        if not source_file.exists():
            raise FileNotFoundError(f"Source file not found: {source_file}")

        current_step = "PARSE_FILE"
        df = parse_file(source_file)

        if df.empty:
            raise ValueError(f"Source file is empty: {source_file.name}")

        print(f"Raw shape: {df.shape[0]} rows x {df.shape[1]} columns")

        current_step = "ADD_METADATA"
        df = add_metadata(
            df=df,
            source_file=source_file.name,
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
            source_file=source_file.name,
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

        return rows_loaded

    except Exception as e:
        finished_at = datetime.now()
        duration_sec = round(time.time() - start_time, 2)

        write_ingest_log(
            batch_id=batch_id,
            source_name=TABLE_NAME,
            source_file=source_file.name,
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
        print(f"Failed file: {source_file.name}")
        print(f"Failed step: {current_step}")
        print(e)

        return 0


def run():
    create_ingest_log_table()

    files = sorted(SOURCE_FOLDER.glob(FILE_PATTERN))

    print(f"Source folder: {SOURCE_FOLDER}")
    print(f"File pattern: {FILE_PATTERN}")
    print(f"Files found: {len(files)}")

    if not files:
        raise FileNotFoundError(
            f"No files found in {SOURCE_FOLDER} with pattern {FILE_PATTERN}"
        )

    total_loaded = 0

    for source_file in files:
        loaded_rows = load_one_file(source_file)
        total_loaded += loaded_rows

    print("=" * 80)
    print(f"DONE: loaded total {total_loaded} rows into raw.{TABLE_NAME}")
    print(f"Files processed: {len(files)}")


if __name__ == "__main__":
    run()