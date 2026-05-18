# Setup Notes

## Environment

Python virtual environment was created with:

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

## Install dependencies

Dependencies were installed with:

```bash
pip install -r 00_setup/requirements.txt
```

## Verification

Python packages were tested with:

```bash
python -c "import pandas, sqlalchemy, psycopg2, dotenv; print('OK')"
```

Expected output:

```text
OK
```