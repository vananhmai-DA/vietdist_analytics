import sys
from pathlib import Path

from sqlalchemy import text

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(PROJECT_ROOT / "01_ingestion"))

from utils.db_utils import get_engine


def run_sql_file(sql_file_path: str):
    sql_path = PROJECT_ROOT / sql_file_path

    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    sql = sql_path.read_text(encoding="utf-8")

    engine = get_engine()

    with engine.begin() as conn:
        conn.execute(text(sql))

    print(f"Successfully executed: {sql_file_path}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python 02_sql_analytics/run_sql_file.py <sql_file_path>")
        sys.exit(1)

    run_sql_file(sys.argv[1])