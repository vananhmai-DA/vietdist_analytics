import sys
from pathlib import Path

from sqlalchemy import text

# Add 01_ingestion folder to Python path
PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(PROJECT_ROOT / "01_ingestion"))

from utils.db_utils import get_engine


TABLE_PROFILES = {
    "sales_transactions": {
        "table": "raw.sales_transactions",
        "key_columns": ["order_id"],
        "duplicate_columns": ["order_id", "product_id"],
    },
    "sales_target_plan": {
        "table": "raw.sales_target_plan",
        "key_columns": ["plan_version", "employee_id", "month"],
        "duplicate_columns": ["plan_version", "employee_id", "year", "month"],
    },
    "sales_targets_raw": {
        "table": "raw.sales_targets_raw",
        "key_columns": ["version_label", "employee_id", "month_col"],
        "duplicate_columns": ["version_label", "employee_id", "year", "month_col"],
    },
    "customer_master": {
        "table": "raw.customer_master",
        "key_columns": ["customer_id"],
        "duplicate_columns": ["customer_id"],
    },
    "product_master": {
        "table": "raw.product_master",
        "key_columns": ["product_id"],
        "duplicate_columns": ["product_id"],
    },
    "distributor_orders": {
        "table": "raw.distributor_orders",
        "key_columns": ["order_id", "distributor_id", "product_id"],
        "duplicate_columns": ["order_id", "distributor_id", "product_id"],
    },
    "distributor_master": {
        "table": "raw.distributor_master",
        "key_columns": ["distributor_id"],
        "duplicate_columns": ["distributor_id"],
    },
    "employee_master": {
        "table": "raw.employee_master",
        "key_columns": ["employee_id"],
        "duplicate_columns": ["employee_id", "effective_date"],
    },
    "territory_mapping": {
        "table": "raw.territory_mapping",
        "key_columns": ["territory_id", "employee_id", "customer_id"],
        "duplicate_columns": ["territory_id", "employee_id", "customer_id", "effective_date"],
    },
    "return_transactions": {
        "table": "raw.return_transactions",
        "key_columns": ["return_id"],
        "duplicate_columns": ["return_id"],
    },
    "promotion_program": {
        "table": "raw.promotion_program",
        "key_columns": ["promotion_id"],
        "duplicate_columns": ["promotion_id"],
    },
}


def get_row_count(conn, table_name: str) -> int:
    return conn.execute(text(f"SELECT COUNT(*) FROM {table_name};")).scalar()


def get_null_count(conn, table_name: str, column_name: str) -> int:
    sql = f"""
        SELECT COUNT(*)
        FROM {table_name}
        WHERE {column_name} IS NULL
           OR TRIM(CAST({column_name} AS TEXT)) = ''
           OR LOWER(TRIM(CAST({column_name} AS TEXT))) IN ('nan', 'none', 'null');
    """
    return conn.execute(text(sql)).scalar()


def get_duplicate_count(conn, table_name: str, duplicate_columns: list[str]) -> int:
    cols = ", ".join(duplicate_columns)

    sql = f"""
        SELECT COALESCE(SUM(duplicate_rows), 0)
        FROM (
            SELECT COUNT(*) - 1 AS duplicate_rows
            FROM {table_name}
            GROUP BY {cols}
            HAVING COUNT(*) > 1
        ) dup;
    """

    return conn.execute(text(sql)).scalar()


def profile_table(conn, profile_name: str, config: dict) -> dict:
    table_name = config["table"]
    key_columns = config["key_columns"]
    duplicate_columns = config["duplicate_columns"]

    row_count = get_row_count(conn, table_name)

    null_results = []
    for col in key_columns:
        null_count = get_null_count(conn, table_name, col)
        null_pct = round((null_count / row_count) * 100, 2) if row_count else 0

        null_results.append(
            {
                "column": col,
                "null_count": null_count,
                "null_pct": null_pct,
            }
        )

    duplicate_count = get_duplicate_count(conn, table_name, duplicate_columns)

    return {
        "profile_name": profile_name,
        "table": table_name,
        "row_count": row_count,
        "key_nulls": null_results,
        "duplicate_columns": duplicate_columns,
        "duplicate_count": duplicate_count,
    }


def main():
    engine = get_engine()
    results = []

    with engine.connect() as conn:
        for profile_name, config in TABLE_PROFILES.items():
            print("\n" + "=" * 90)
            print(f"Profiling: {config['table']}")
            print("=" * 90)

            result = profile_table(conn, profile_name, config)
            results.append(result)

            print(f"Row count: {result['row_count']}")

            print("\nKey column null checks:")
            for item in result["key_nulls"]:
                print(
                    f"- {item['column']:<25} "
                    f"null_count={item['null_count']:<8} "
                    f"null_pct={item['null_pct']}%"
                )

            print("\nDuplicate check:")
            print(f"- Duplicate columns: {', '.join(result['duplicate_columns'])}")
            print(f"- Duplicate rows: {result['duplicate_count']}")

    print("\n" + "#" * 90)
    print("SUMMARY FOR docs/data_issues.md")
    print("#" * 90)

    for result in results:
        print(
            f"| {result['table']} | {result['row_count']} | "
            f"{result['duplicate_count']} | "
            f"{', '.join([f'{x['column']}: {x['null_pct']}%' for x in result['key_nulls']])} |"
        )


if __name__ == "__main__":
    main()