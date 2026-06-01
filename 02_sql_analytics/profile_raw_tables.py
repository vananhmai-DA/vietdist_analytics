import sys
from pathlib import Path
from typing import Optional

from sqlalchemy import text

# This file is located at:
# 02_sql_analytics/profile_raw_tables.py
PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(PROJECT_ROOT / "01_ingestion"))

from utils.db_utils import get_engine


TABLE_PROFILES = {
    "sales_transactions": {
        "table": "raw.sales_transactions",
        "source_name": "sales_transactions",
        "key_columns": ["order_id", "product_id"],
        "duplicate_columns": ["order_id", "product_id"],
        "use_latest_batch": True,
    },
    "customer_master": {
        "table": "raw.customer_master",
        "source_name": "customer_master",
        "key_columns": ["customer_id"],
        "duplicate_columns": ["customer_id"],
        "use_latest_batch": True,
    },
    "product_master": {
        "table": "raw.product_master",
        "source_name": "product_master",
        "key_columns": ["product_id"],
        "duplicate_columns": ["product_id"],
        "use_latest_batch": True,
    },
    "distributor_orders": {
        "table": "raw.distributor_orders",
        "source_name": "distributor_orders",
        "key_columns": ["order_id", "distributor_id", "product_id"],
        "duplicate_columns": ["order_id", "distributor_id", "product_id"],
        "use_latest_batch": True,
    },
    "distributor_master": {
        "table": "raw.distributor_master",
        "source_name": "distributor_master",
        "key_columns": ["distributor_id"],
        "duplicate_columns": ["distributor_id"],
        "use_latest_batch": True,
    },
    "employee_master": {
        "table": "raw.employee_master",
        "source_name": "employee_master",
        "key_columns": ["employee_id", "effective_date"],
        "duplicate_columns": ["employee_id", "effective_date"],
        "use_latest_batch": True,
    },
    "territory_mapping": {
        "table": "raw.territory_mapping",
        "source_name": "territory_mapping",
        "key_columns": ["territory_id", "employee_id", "customer_id", "effective_date"],
        "duplicate_columns": ["territory_id", "employee_id", "customer_id", "effective_date"],
        "use_latest_batch": True,
    },
    "return_transactions": {
        "table": "raw.return_transactions",
        "source_name": "return_transactions",
        "key_columns": ["return_id"],
        "duplicate_columns": ["return_id"],
        "use_latest_batch": True,
    },
    "promotion_program": {
        "table": "raw.promotion_program",
        "source_name": "promotion_program",
        "key_columns": ["promotion_id"],
        "duplicate_columns": ["promotion_id"],
        "use_latest_batch": True,
    },

    # Special versioning table:
    # Keep full history because Silver model needs all versions to calculate is_latest.
    "sales_targets_raw": {
        "table": "raw.sales_targets_raw",
        "source_name": None,
        "key_columns": ["version_label", "employee_id", "month_col"],
        "duplicate_columns": ["version_label", "employee_id", "year", "month_col"],
        "use_latest_batch": False,
    },
}


def get_latest_success_batch_id(conn, source_name: str) -> Optional[str]:
    sql = """
        SELECT batch_id
        FROM raw.ingest_log
        WHERE source_name = :source_name
          AND status = 'SUCCESS'
        ORDER BY finished_at DESC
        LIMIT 1;
    """

    return conn.execute(
        text(sql),
        {"source_name": source_name},
    ).scalar()


def build_scope_filter(batch_id: Optional[str], use_latest_batch: bool) -> tuple[str, dict]:
    if use_latest_batch:
        if batch_id is None:
            return "WHERE 1 = 0", {}

        return "WHERE _batch_id = :batch_id", {"batch_id": batch_id}

    return "", {}


def get_row_count(conn, table_name: str, scope_filter: str, params: dict) -> int:
    sql = f"""
        SELECT COUNT(*)
        FROM {table_name}
        {scope_filter};
    """

    return conn.execute(text(sql), params).scalar()


def get_null_count(
    conn,
    table_name: str,
    column_name: str,
    scope_filter: str,
    params: dict,
) -> int:
    where_keyword = "AND" if scope_filter else "WHERE"

    sql = f"""
        SELECT COUNT(*)
        FROM {table_name}
        {scope_filter}
        {where_keyword} (
            {column_name} IS NULL
            OR TRIM(CAST({column_name} AS TEXT)) = ''
            OR LOWER(TRIM(CAST({column_name} AS TEXT))) IN ('nan', 'none', 'null', 'nat')
        );
    """

    return conn.execute(text(sql), params).scalar()


def get_duplicate_count(
    conn,
    table_name: str,
    duplicate_columns: list[str],
    scope_filter: str,
    params: dict,
) -> int:
    cols = ", ".join(duplicate_columns)

    sql = f"""
        SELECT COALESCE(SUM(duplicate_rows), 0)
        FROM (
            SELECT COUNT(*) - 1 AS duplicate_rows
            FROM {table_name}
            {scope_filter}
            GROUP BY {cols}
            HAVING COUNT(*) > 1
        ) dup;
    """

    return conn.execute(text(sql), params).scalar()


def profile_table(conn, profile_name: str, config: dict) -> dict:
    table_name = config["table"]
    source_name = config["source_name"]
    key_columns = config["key_columns"]
    duplicate_columns = config["duplicate_columns"]
    use_latest_batch = config["use_latest_batch"]

    latest_batch_id = None
    if use_latest_batch:
        latest_batch_id = get_latest_success_batch_id(conn, source_name)

    scope_filter, params = build_scope_filter(
        batch_id=latest_batch_id,
        use_latest_batch=use_latest_batch,
    )

    row_count = get_row_count(
        conn=conn,
        table_name=table_name,
        scope_filter=scope_filter,
        params=params,
    )

    null_results = []
    for col in key_columns:
        null_count = get_null_count(
            conn=conn,
            table_name=table_name,
            column_name=col,
            scope_filter=scope_filter,
            params=params,
        )

        null_pct = round((null_count / row_count) * 100, 2) if row_count else 0

        null_results.append(
            {
                "column": col,
                "null_count": null_count,
                "null_pct": null_pct,
            }
        )

    duplicate_count = get_duplicate_count(
        conn=conn,
        table_name=table_name,
        duplicate_columns=duplicate_columns,
        scope_filter=scope_filter,
        params=params,
    )

    return {
        "profile_name": profile_name,
        "table": table_name,
        "source_name": source_name,
        "use_latest_batch": use_latest_batch,
        "latest_batch_id": latest_batch_id,
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

            if result["use_latest_batch"]:
                print(f"Latest SUCCESS batch_id: {result['latest_batch_id']}")
            else:
                print("Batch scope: full table history")

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

    print("| Table | Scope | Row Count | Duplicate Rows | Key Null % |")
    print("|---|---|---:|---:|---|")

    for result in results:
        if result["use_latest_batch"]:
            scope = f"latest batch: {result['latest_batch_id']}"
        else:
            scope = "full history"

        null_summary = ", ".join(
            [f"{x['column']}: {x['null_pct']}%" for x in result["key_nulls"]]
        )

        print(
            f"| {result['table']} | {scope} | {result['row_count']} | "
            f"{result['duplicate_count']} | {null_summary} |"
        )


if __name__ == "__main__":
    main()