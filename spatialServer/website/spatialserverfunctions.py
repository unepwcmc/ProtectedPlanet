import json
import sys

import psycopg2
from twisted.web.server import Request

from postgres.postgresexecutor import PostgresExecutor
from sql.sqlrunner import SqlRunner
from website.geometryinteractionexception import GeometryIntersectionException


def return_home_page(_):
    return bytes('This is the spatial server', 'utf-8')


def connection_string():
    connection_str = f"dbname={dbname} user={username} password={password} host={hostname}"
    print(connection_str)
    return connection_str


def install_server(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            cursor = PostgresExecutor.begin_transaction()
            SqlRunner.execute(cursor, '../sql/geometry_intersection.sql')
            return b'Completed'
        except Exception as e:
            print(str(e))
            PostgresExecutor.rollback()
            return b'Failed'


def geometry_intersection(request: Request):
    data = request.content.read()
    data = bytes.decode(data, 'utf-8')
    json_payload = json.loads(data)
    if json_payload.get("threshold") is None:
        raise GeometryIntersectionException(b'No threshold specified')
    threshold = float(json_payload.get("threshold"))
    if json_payload.get("areas") is None:
        raise GeometryIntersectionException(b'No areas specified')
    request_id = 1
    answers = {}
    sql_inserts = []
    for submission in json_payload.get("areas"):
        draft_id = submission.get('draft_id')
        iso3 = submission.get('iso3')
        shape = submission.get('shape')
        if draft_id is None or iso3 is None or shape is None:
            raise GeometryIntersectionException("One of draft_id, iso3 or shape is missing from the JSON")
        if answers.get(draft_id) is None:
            answers[draft_id] = {"draft_id": draft_id,
                                 "iso3": iso3,
                                 "mismatches": []
                                 }
        sql = "INSERT INTO wdpa_geoms(draft_id, request_id, iso3, shape) VALUES "
        sql += f"({draft_id}, {request_id}, '{iso3}', '{shape}') "
        sql_inserts.append(sql)
    print(f'Inserting {len(sql_inserts)} rows')
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            cursor = PostgresExecutor.begin_transaction()
            cursor.execute('DELETE FROM wdpa_geoms')
            cursor.execute('DELETE FROM geometry_validation')
            for sql in sql_inserts:
                cursor.execute(sql)
            cursor.execute('SELECT COUNT(1) FROM wdpa_geoms')
            rows = cursor.fetchone()
            print(f'Confirming: insert {rows[0][0]} rows')
            PostgresExecutor.end_transaction()
            cursor = PostgresExecutor.begin_transaction()
            cursor.execute('SELECT geometry_validation_proc(%s)', (threshold,))
            cursor.execute(f"SELECT draft_id, iso3, base_layer_iso3, misassigned_ratio, misassigned_geom FROM geometry_validation")
            rows = cursor.fetchall()
            for row in rows:
                draft_id = row[0]
                iso3 = row[1]
                base_layer_iso3 = row[2]
                misassigned_ratio = row[3]
                misassigned_geom = row[4]
                misassigned = {"base_layer_iso3": base_layer_iso3,
                               "misassigned_ratio": misassigned_ratio,
                               "misassigned_geom": misassigned_geom
                              }
                answers[draft_id]["mismatches"].append(misassigned)
            PostgresExecutor.end_transaction()
            answer_to_return = { "data": list(answers.values())}
            return bytes(json.dumps(answer_to_return), 'utf-8')
        except Exception as e:
            print(str(e))
            PostgresExecutor.rollback()
            return b'Failed to insert row'


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
