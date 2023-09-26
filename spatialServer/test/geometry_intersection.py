import sys

import psycopg2
import requests

from postgres.postgresexecutor import PostgresExecutor

# build up the json we want to send

req = {
    "threshold" : 0,
    "areas" : [
        {
            "draft_id": 6,
            "iso3": "ARG",
            "shape": "<insert geom here>"
        },
        {
            "draft_id": 6,
            "iso3": "ARG",
            "shape": "<insert geom here>"
        }
    ]
}

if len(sys.argv) >= 2:
    port = int(sys.argv[1])
else:
    port = 8080

if len(sys.argv) >= 3:
    username = sys.argv[2]
else:
    username = "postgres"

if len(sys.argv) >= 4:
    dbname = sys.argv[3]
else:
    dbname = "WDPA"

if len(sys.argv) >= 5:
    hostname = sys.argv[4]
else:
    hostname = "127.0.0.1"

if len(sys.argv) >= 6:
    password = sys.argv[5]
else:
    password = "WCMC%1"

def connection_string():
    connection_str = f"dbname={dbname} user={username} password={password} host={hostname}"
    print(connection_str)
    return connection_str

with psycopg2.connect(connection_string()) as conn:
    try:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.begin_transaction()
        for area in req["areas"]:
            draft_id = area["draft_id"]
            cursor.execute(f'SELECT geom from SPATIAL_DATA where site_id={draft_id}')
            row = cursor.fetchone()
            area["shape"] = row[0]
        url = "http://127.0.0.1:8090/geometry_intersection"
        # ans is a Requests.response object
        ans = requests.post(url, json = req)
        print(ans)
        print(ans.text)
    except Exception as e:
        print(str(e))
    finally:
        PostgresExecutor.rollback()