from pathlib import Path
from utils.file_parser import parse_file

RAW_DATA_DIR = Path("data/raw")

def main():
    files = list(RAW_DATA_DIR.glob("*"))

    print(f"Found {len(files)} file(s) in {RAW_DATA_DIR}")

    for file_path in files:
        if file_path.is_dir():
            continue

        print("\n" + "=" * 80)
        print(f"Reading: {file_path.name}")

        try:
            df = parse_file(file_path)
            print(f"OK - shape: {df.shape[0]} rows x {df.shape[1]} columns")
            print("Columns:")
            print(list(df.columns))
            print("Preview:")
            print(df.head(3))
        except Exception as e:
            print(f"FAILED - {e}")

if __name__ == "__main__":
    main()