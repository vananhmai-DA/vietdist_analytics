import sys
import time
import uuid
from pathlib import Path
from datetime import datetime

from sqlalchemy import text

# Add 01_ingestion folder to Python path
sys.path.append(str(Path(__file__).resolve().parents[1]))

from utils.file_parser import parse_file
from utils.db_utils import (
    add_metadata,
    load_to_bronze,
    get_engine,
    create_ingest_log_table,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]


SOURCE_FILE = PROJECT_ROOT / "data" / "raw" / "SRC06_distributor_master.csv"
TABLE_NAME = "distributor_master"
SOURCE_PLATFORM = "local"


def run():
    batch_id = str(uuid.uuid4())
    started_at = datetime.now()
    start_time = time.time()

    engine = get_engine()
    create_ingest_log_table()

    try:
        print(f"Reading file: {SOURCE_FILE}")

        df = parse_file(SOURCE_FILE)
        print(f"Raw shape: {df.shape[0]} rows x {df.shape[1]} columns")

        df = add_metadata(
            df=df,
            source_file=SOURCE_FILE.name,
            source_platform=SOURCE_PLATFORM,
            batch_id=batch_id,
        )

        rows_loaded = load_to_bronze(
            df=df,
            table_name=TABLE_NAME,
            if_exists="append",
        )

        finished_at = datetime.now()
        duration_sec = round(time.time() - start_time, 2)

        with engine.begin() as conn:
            conn.execute(
                text("""
                    INSERT INTO raw.ingest_log (
                        batch_id,
                        source_name,
                        source_file,
                        source_platform,
                        rows_loaded,
                        status,
                        error_message,
                        started_at,
                        finished_at,
                        duration_sec
                    )
                    VALUES (
                        :batch_id,
                        :source_name,
                        :source_file,
                        :source_platform,
                        :rows_loaded,
                        :status,
                        :error_message,
                        :started_at,
                        :finished_at,
                        :duration_sec
                    )
                """),
                {
                    "batch_id": batch_id,
                    "source_name": TABLE_NAME,
                    "source_file": SOURCE_FILE.name,
                    "source_platform": SOURCE_PLATFORM,
                    "rows_loaded": rows_loaded,
                    "status": "SUCCESS",
                    "error_message": None,
                    "started_at": started_at,
                    "finished_at": finished_at,
                    "duration_sec": duration_sec,
                },
            )

        print(f"SUCCESS: loaded {rows_loaded} rows into raw.{TABLE_NAME}")

    except Exception as e:
        finished_at = datetime.now()
        duration_sec = round(time.time() - start_time, 2)

        with engine.begin() as conn:
            conn.execute(
                text("""
                    INSERT INTO raw.ingest_log (
                        batch_id,
                        source_name,
                        source_file,
                        source_platform,
                        rows_loaded,
                        status,
                        error_message,
                        started_at,
                        finished_at,
                        duration_sec
                    )
                    VALUES (
                        :batch_id,
                        :source_name,
                        :source_file,
                        :source_platform,
                        :rows_loaded,
                        :status,
                        :error_message,
                        :started_at,
                        :finished_at,
                        :duration_sec
                    )
                """),
                {
                    "batch_id": batch_id,
                    "source_name": TABLE_NAME,
                    "source_file": SOURCE_FILE.name,
                    "source_platform": SOURCE_PLATFORM,
                    "rows_loaded": 0,
                    "status": "FAILED",
                    "error_message": str(e),
                    "started_at": started_at,
                    "finished_at": finished_at,
                    "duration_sec": duration_sec,
                },
            )

        print("FAILED")
        print(e)


if __name__ == "__main__":
    run()