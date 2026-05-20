from sqlalchemy import text
from utils.db_utils import get_engine

EXPECTED_TABLES = [
    "sales_transactions",
    "sales_target_plan",
    "customer_master",
    "product_master",
    "distributor_orders",
    "distributor_master",
    "employee_master",
    "territory_mapping",
    "return_transactions",
    "promotion_program",
]


def main():
    engine = get_engine()

    with engine.connect() as conn:
        print("Bronze table row counts")
        print("=" * 60)

        for table_name in EXPECTED_TABLES:
            result = conn.execute(
                text(f"SELECT COUNT(*) FROM raw.{table_name};")
            )
            row_count = result.scalar()
            print(f"{table_name:<30} {row_count:>10} rows")

        print("\nLatest ingest logs")
        print("=" * 60)

        logs = conn.execute(
            text("""
                SELECT source_name, source_file, rows_loaded, status, finished_at
                FROM raw.ingest_log
                ORDER BY log_id DESC
                LIMIT 10;
            """)
        )

        for row in logs:
            print(
                f"{row.source_name:<30} "
                f"{row.rows_loaded:>10} rows "
                f"{row.status:<10} "
                f"{row.source_file}"
            )


if __name__ == "__main__":
    main()