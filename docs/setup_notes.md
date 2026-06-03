# Setup Notes

## Objective

This document records the environment setup for the VietDist Analytics project.

The project uses two Python virtual environments:

| Environment | Purpose |
|---|---|
| `venv` | Python ingestion, raw profiling, utility scripts |
| `venv_dbt` | dbt Silver and Gold transformation pipeline |

Keeping dbt in a separate environment helps avoid package conflicts between ingestion scripts and dbt dependencies.

---

## 1. Main Python Environment

The main Python virtual environment was created with:

```bash
python -m venv venv
```

Activated on Windows PowerShell with:

```powershell
.\venv\Scripts\Activate.ps1
```

If PowerShell blocks script execution, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then activate again:

```powershell
.\venv\Scripts\Activate.ps1
```

This environment is used for:

- Bronze ingestion scripts
- File parsing
- Raw table profiling
- Database utility scripts

---

## 2. Install Python Dependencies

Dependencies were installed with:

```bash
pip install -r 00_setup/requirements.txt
```

---

## 3. Verify Python Packages

Python packages were tested with:

```bash
python -c "import pandas, sqlalchemy, psycopg2, dotenv; print('OK')"
```

Expected output:

```text
OK
```

---

## 4. dbt Environment

A separate virtual environment was created for dbt:

```bash
python -m venv venv_dbt
```

Activated on Windows PowerShell with:

```powershell
.\venv_dbt\Scripts\Activate.ps1
```

This environment is used for:

- dbt Silver models
- dbt Gold models
- dbt tests
- dbt lineage and model execution

---

## 5. Install dbt Dependencies

dbt PostgreSQL dependencies were installed in `venv_dbt`.

Example:

```bash
pip install dbt-postgres
```

dbt version was checked with:

```bash
dbt --version
```

Expected environment:

```text
dbt-core 1.x
dbt-postgres 1.x
```

In this project, dbt was run successfully with:

```text
dbt=1.11.11
postgres adapter=1.9.0
```

---

## 6. PostgreSQL Database

The project uses PostgreSQL as the local data warehouse.

Database name:

```text
vietdist_dw
```

Main schemas:

| Schema | Purpose |
|---|---|
| `raw` | Bronze Layer |
| `silver` | Silver Layer |
| `gold` | Gold Layer |

The original project brief used `staging` and `dwh`, but the implemented dbt version uses `silver` and `gold` to match the Medallion Architecture more clearly.

---

## 7. Environment Usage Rule

Use the main environment for ingestion and profiling:

```powershell
.\venv\Scripts\Activate.ps1
python 02_sql_analytics/profile_raw_tables.py
```

Use the dbt environment for Silver and Gold transformations:

```powershell
.\venv_dbt\Scripts\Activate.ps1
cd 02_sql_analytics/dbt
dbt run --select silver
dbt test --select silver
dbt run --select gold
dbt test --select gold
```

---

## 8. Security Notes

Sensitive files should not be committed to GitHub.

The following should be listed in `.gitignore`:

```text
.env
credentials/
/data/
/logs/
/venv/
/venv_dbt/
02_sql_analytics/dbt/target/
02_sql_analytics/dbt/logs/
02_sql_analytics/dbt/dbt_packages/
```

The `data/` folder is kept local because it contains raw sample files.

---

## 9. Final Verification

The project setup is considered valid when:

- Python environment activates successfully
- Required Python packages import successfully
- PostgreSQL database `vietdist_dw` is accessible
- Raw ingestion scripts can load data into `raw`
- dbt environment activates successfully
- `dbt debug` passes
- `dbt run --select silver --full-refresh` runs successfully
- `dbt test --select silver` passes
- `dbt run --select gold --full-refresh` runs successfully
- `dbt test --select gold` passes

Latest validation status:

```text
Silver tests: PASS
Gold tests: PASS=61, WARN=0, ERROR=0
```