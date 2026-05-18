import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

load_dotenv()

db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")

connection_url = URL.create(
    drivername="postgresql+psycopg2",
    username=db_user,
    password=db_password,
    host=db_host,
    port=db_port,
    database=db_name,
)

engine = create_engine(connection_url)

try:
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT schema_name
                FROM information_schema.schemata
                WHERE schema_name IN ('raw', 'staging', 'dwh')
                ORDER BY schema_name;
            """)
        )

        print("Connected to PostgreSQL successfully.")
        print("Schemas found:")

        for row in result:
            print("-", row[0])

except Exception as e:
    print("Connection failed.")
    print(e)