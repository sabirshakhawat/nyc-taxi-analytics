from pathlib import Path
import sys

import duckdb


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATABASE_PATH = PROJECT_ROOT / "database" / "taxi.duckdb"


def main():
    if len(sys.argv) != 2:
        print("Usage: python scripts/run_sql.py <sql-file>")
        raise SystemExit(1)

    sql_path = PROJECT_ROOT / sys.argv[1]

    if not sql_path.exists():
        print(f"SQL file not found: {sql_path}")
        raise SystemExit(1)

    sql = sql_path.read_text()
    connection = duckdb.connect(str(DATABASE_PATH))

    try:
        result = connection.execute(sql)

        if result.description:
            column_names = [column[0] for column in result.description]
            rows = result.fetchall()

            print(column_names)
            for row in rows:
                print(row)
        else:
            print("SQL completed successfully.")
    finally:
        connection.close()


if __name__ == "__main__":
    main()