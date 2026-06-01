from pathlib import Path

from utils.file_parser import parse_file


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"


def main():
    files = sorted(RAW_DATA_DIR.glob("*"))

    print("Raw file read check")
    print("=" * 80)
    print(f"Source folder: {RAW_DATA_DIR}")
    print(f"Files found: {len(files)}")

    for file_path in files:
        if file_path.is_dir():
            continue

        print("\n" + "-" * 80)
        print(f"Reading: {file_path.name}")

        try:
            df = parse_file(file_path)

            print("Status: OK")
            print(f"Shape: {df.shape[0]} rows x {df.shape[1]} columns")
            print("Columns:")
            print(list(df.columns))
            print("Preview:")
            print(df.head(3))

        except Exception as e:
            print("Status: FAILED")
            print(f"Error: {e}")


if __name__ == "__main__":
    main()