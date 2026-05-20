from pathlib import Path
import pandas as pd


def parse_file(file_path: str | Path, sheet_name=0) -> pd.DataFrame:
    """
    Read a local raw data file into a pandas DataFrame.

    Supported formats:
    - .csv
    - .xlsx
    - .xls
    - .xlsm
    - .xlsb
    """
    file_path = Path(file_path)
    suffix = file_path.suffix.lower()

    if suffix == ".csv":
        return pd.read_csv(file_path, encoding="utf-8-sig")

    if suffix in [".xlsx", ".xls", ".xlsm"]:
        return pd.read_excel(file_path, sheet_name=sheet_name, engine="openpyxl")

    if suffix == ".xlsb":
        return pd.read_excel(file_path, sheet_name=sheet_name, engine="pyxlsb")

    raise ValueError(f"Unsupported file format: {suffix}")


def preview_file(file_path: str | Path, n: int = 5, sheet_name=0) -> None:
    """
    Preview a file quickly in terminal.
    """
    df = parse_file(file_path, sheet_name=sheet_name)

    print(f"File: {file_path}")
    print(f"Shape: {df.shape[0]} rows x {df.shape[1]} columns")
    print("\nColumns:")
    print(list(df.columns))
    print("\nPreview:")
    print(df.head(n))