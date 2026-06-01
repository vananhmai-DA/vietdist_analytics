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

SPECIAL_TARGET_TABLES = [
    "sales_target_files",
    "sales_targets_raw",
    "sales_target_versions",
]

METADATA_COLUMNS = [
    "_source_file",
    "_source_platform",
    "_ingested_at",
    "_batch_id",
]


def table_exists(conn, schema_name: str, table_name: str) -> bool:
    result = conn.execute(
        text("""
            SELECT EXISTS (
                SELECT 1
                FROM information_schema.tables
                WHERE table_schema = :schema_name
                  AND table_name = :table_name
            );
        """),
        {
            "schema_name": schema_name,
            "table_name": table_name,
        },
    )

    return result.scalar()


def get_row_count(conn, schema_name: str, table_name: str) -> int:
    result = conn.execute(
        text(f"SELECT COUNT(*) FROM {schema_name}.{table_name};")
    )

    return result.scalar()


def get_latest_success_log(conn, source_name: str):
    result = conn.execute(
        text("""
            SELECT
                source_name,
                source_file,
                rows_loaded,
                status,
                failed_step,
                error_message,
                finished_at
            FROM raw.ingest_log
            WHERE source_name = :source_name
              AND status = 'SUCCESS'
            ORDER BY log_id DESC
            LIMIT 1;
        """),
        {"source_name": source_name},
    )

    return result.fetchone()


def get_latest_any_log(conn, source_name: str):
    result = conn.execute(
        text("""
            SELECT
                source_name,
                source_file,
                rows_loaded,
                status,
                failed_step,
                error_message,
                finished_at
            FROM raw.ingest_log
            WHERE source_name = :source_name
            ORDER BY log_id DESC
            LIMIT 1;
        """),
        {"source_name": source_name},
    )

    return result.fetchone()


def get_existing_columns(conn, schema_name: str, table_name: str) -> set:
    result = conn.execute(
        text("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = :schema_name
              AND table_name = :table_name;
        """),
        {
            "schema_name": schema_name,
            "table_name": table_name,
        },
    )

    return {row.column_name for row in result}


def check_main_bronze_tables(conn):
    print("\nBronze table row counts")
    print("=" * 120)
    print(
        f"{'Table':<30} "
        f"{'Exists':<8} "
        f"{'Total Rows':>12} "
        f"{'Latest Rows':>12} "
        f"{'Latest Status':<15} "
        f"{'Source File'}"
    )
    print("-" * 120)

    for table_name in EXPECTED_TABLES:
        exists = table_exists(conn, "raw", table_name)

        if not exists:
            print(
                f"{table_name:<30} "
                f"{'NO':<8} "
                f"{'-':>12} "
                f"{'-':>12} "
                f"{'MISSING':<15} "
                f"-"
            )
            continue

        total_rows = get_row_count(conn, "raw", table_name)
        latest_success_log = get_latest_success_log(conn, table_name)

        if latest_success_log:
            latest_rows = latest_success_log.rows_loaded
            latest_status = latest_success_log.status
            source_file = latest_success_log.source_file
        else:
            latest_rows = "-"
            latest_status = "NO SUCCESS"
            source_file = "-"

        print(
            f"{table_name:<30} "
            f"{'YES':<8} "
            f"{total_rows:>12} "
            f"{latest_rows:>12} "
            f"{latest_status:<15} "
            f"{source_file}"
        )


def check_metadata_columns(conn):
    print("\nMetadata column check")
    print("=" * 100)
    print(f"{'Table':<30} {'Metadata Status':<20} {'Missing Columns'}")
    print("-" * 100)

    for table_name in EXPECTED_TABLES:
        exists = table_exists(conn, "raw", table_name)

        if not exists:
            print(f"{table_name:<30} {'TABLE MISSING':<20} -")
            continue

        existing_columns = get_existing_columns(conn, "raw", table_name)

        missing_columns = [
            col for col in METADATA_COLUMNS
            if col not in existing_columns
        ]

        if missing_columns:
            print(
                f"{table_name:<30} "
                f"{'MISSING':<20} "
                f"{', '.join(missing_columns)}"
            )
        else:
            print(f"{table_name:<30} {'OK':<20} -")


def check_latest_status_by_source(conn):
    print("\nLatest status by source")
    print("=" * 120)
    print(
        f"{'Source Name':<30} "
        f"{'Latest Status':<15} "
        f"{'Rows':>10} "
        f"{'Failed Step':<25} "
        f"{'Source File'}"
    )
    print("-" * 120)

    for source_name in EXPECTED_TABLES:
        latest_log = get_latest_any_log(conn, source_name)

        if not latest_log:
            print(
                f"{source_name:<30} "
                f"{'NO LOG':<15} "
                f"{'-':>10} "
                f"{'-':<25} "
                f"-"
            )
            continue

        failed_step = latest_log.failed_step if latest_log.failed_step else "-"
        source_file = latest_log.source_file if latest_log.source_file else "-"

        print(
            f"{source_name:<30} "
            f"{latest_log.status:<15} "
            f"{latest_log.rows_loaded:>10} "
            f"{failed_step:<25} "
            f"{source_file}"
        )


def check_recent_failed_logs(conn):
    print("\nRecent failed ingest logs")
    print("=" * 120)

    failed_logs = conn.execute(
        text("""
            SELECT
                source_name,
                source_file,
                rows_loaded,
                status,
                failed_step,
                error_message,
                finished_at
            FROM raw.ingest_log
            WHERE status = 'FAILED'
            ORDER BY log_id DESC
            LIMIT 10;
        """)
    ).fetchall()

    if not failed_logs:
        print("No failed logs found.")
        return

    for row in failed_logs:
        failed_step = row.failed_step if row.failed_step else "-"
        error_message = row.error_message if row.error_message else "-"

        if len(error_message) > 180:
            error_message = error_message[:180] + "..."

        print(
            f"{row.source_name:<30} "
            f"{row.rows_loaded:>10} rows "
            f"{row.status:<10} "
            f"step={failed_step:<25} "
            f"file={row.source_file:<35} "
            f"error={error_message}"
        )


def check_sales_target_versioning(conn):
    print("\nSales target versioning tables")
    print("=" * 90)
    print(f"{'Table':<30} {'Exists':<8} {'Rows':>12}")
    print("-" * 90)

    for table_name in SPECIAL_TARGET_TABLES:
        exists = table_exists(conn, "raw", table_name)

        if not exists:
            print(f"{table_name:<30} {'NO':<8} {'-':>12}")
            continue

        row_count = get_row_count(conn, "raw", table_name)

        print(
            f"{table_name:<30} "
            f"{'YES':<8} "
            f"{row_count:>12}"
        )

    if table_exists(conn, "raw", "sales_targets_raw"):
        print("\nRows by target version")
        print("=" * 90)

        rows = conn.execute(
            text("""
                SELECT
                    version_label,
                    sheet_name,
                    COUNT(*) AS row_count
                FROM raw.sales_targets_raw
                GROUP BY
                    version_label,
                    sheet_name
                ORDER BY
                    version_label,
                    sheet_name;
            """)
        )

        for row in rows:
            print(
                f"{row.version_label:<10} "
                f"{row.sheet_name:<30} "
                f"{row.row_count:>10} rows"
            )

        total_rows = conn.execute(
            text("""
                SELECT COUNT(*) AS total_rows_left
                FROM raw.sales_targets_raw
                WHERE
                    LOWER(COALESCE(employee_id, '')) LIKE '%tổng%'
                    OR LOWER(COALESCE(employee_name, '')) LIKE '%tổng%'
                    OR LOWER(COALESCE(month_col, '')) LIKE '%tổng%'
                    OR LOWER(COALESCE(month_col, '')) LIKE '%total%';
            """)
        ).scalar()

        print("\nInvalid total rows check")
        print("=" * 90)
        print(f"Rows containing 'TỔNG' or 'Total': {total_rows}")


def main():
    engine = get_engine()

    with engine.connect() as conn:
        check_main_bronze_tables(conn)
        check_metadata_columns(conn)
        check_latest_status_by_source(conn)
        check_recent_failed_logs(conn)
        check_sales_target_versioning(conn)


if __name__ == "__main__":
    main()