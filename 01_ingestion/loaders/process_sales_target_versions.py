from sqlalchemy import text

import sys
from pathlib import Path

# Add 01_ingestion folder to Python path
sys.path.append(str(Path(__file__).resolve().parents[1]))

from utils.db_utils import get_engine


def create_sales_target_versions_table():
    engine = get_engine()

    sql = """
    DROP TABLE IF EXISTS raw.sales_target_versions;

    CREATE TABLE raw.sales_target_versions AS
    SELECT
        plan_version AS version_label,
        MIN(version_date) AS version_date,
        MIN(effective_from) AS effective_from,
        MAX(effective_to) AS effective_to,
        COUNT(*) AS row_count,
        COUNT(DISTINCT employee_id) AS employee_count,
        COUNT(DISTINCT month) AS month_count,
        MIN(month) AS min_month,
        MAX(month) AS max_month,
        MIN(_source_file) AS source_file,
        MIN(_source_platform) AS source_platform,
        MIN(_ingested_at) AS first_ingested_at,
        MAX(_ingested_at) AS last_ingested_at
    FROM raw.sales_target_plan
    GROUP BY plan_version
    ORDER BY plan_version;
    """

    with engine.begin() as conn:
        conn.execute(text(sql))

    print("raw.sales_target_versions table is ready.")


def validate_sales_target_versions():
    engine = get_engine()

    with engine.connect() as conn:
        print("\nSales target versions")
        print("=" * 80)

        versions = conn.execute(
            text("""
                SELECT
                    version_label,
                    version_date,
                    effective_from,
                    effective_to,
                    row_count,
                    employee_count,
                    month_count,
                    source_file
                FROM raw.sales_target_versions
                ORDER BY version_label;
            """)
        )

        for row in versions:
            print(
                f"{row.version_label:<10} "
                f"version_date={row.version_date} "
                f"effective={row.effective_from} to {row.effective_to} "
                f"rows={row.row_count} "
                f"employees={row.employee_count} "
                f"months={row.month_count} "
                f"source={row.source_file}"
            )

        print("\nDistinct versions from raw.sales_target_plan")
        print("=" * 80)

        distinct_versions = conn.execute(
            text("""
                SELECT DISTINCT plan_version
                FROM raw.sales_target_plan
                ORDER BY plan_version;
            """)
        )

        for row in distinct_versions:
            print("-", row.plan_version)

        print("\nCheck invalid total rows")
        print("=" * 80)

        total_rows = conn.execute(
            text("""
                SELECT COUNT(*)
                FROM raw.sales_target_plan
                WHERE
                    LOWER(COALESCE(employee_id, '')) LIKE '%tổng%'
                    OR LOWER(COALESCE(employee_name, '')) LIKE '%tổng%'
                    OR LOWER(COALESCE(month, '')) LIKE '%tổng%';
            """)
        ).scalar()

        print(f"Rows containing 'TỔNG': {total_rows}")

        print("\nCheck month values")
        print("=" * 80)

        months = conn.execute(
            text("""
                SELECT DISTINCT month
                FROM raw.sales_target_plan
                ORDER BY month;
            """)
        )

        for row in months:
            print("-", row.month)


if __name__ == "__main__":
    create_sales_target_versions_table()
    validate_sales_target_versions()