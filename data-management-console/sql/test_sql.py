import psycopg2

try:
    with psycopg2.connect("dbname=wdpa_refactor_db user=wdpa_refactor") as conn:
        print("OK")
        cursor = conn.cursor()
        cursor.execute('CREATE TABLE IF NOT EXISTS TEST(ID INT)')
        cursor.execute('INSERT INTO TEST(ID) VALUES(1),(2)')
        cursor.execute('SELECT * FROM TEST')
        rows = cursor.fetchall()
        print(rows)
except Exception as e:
    print(str(e))