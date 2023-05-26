from collections import defaultdict
from datetime import datetime
import time
import traceback
from flask import render_template, Flask, jsonify, request
from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from metadata_mgmt.metadata_creator import MetadataCreator
from schema_mgmt.referencedataschema import ReferenceDataSchemaPopulator
from schema_mgmt.stagingdatapromoter import LoaderFromStagingToMain
from qa.validation_checks import QAVerifier
from sql.sql_runner import SqlRunner
from schema_mgmt.wdpa_schema import WDPASchemaPopulator
from translation.translation import QuarantineToStagingTranslator
import psycopg2
import sys

app = Flask(__name__)
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True


def get_all_schemas():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as connection:
        cursor = connection.cursor()
        sql = "SELECT DISTINCT SchemaName FROM METADATA"
        cursor.execute(sql)
        rows = cursor.fetchall()
        return [row[0] for row in rows]


@app.route('/South_Africa_Metrics', methods=['GET'])
def metrics():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        cursor = PostgresExecutor.begin_transaction(conn)
        years = [2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024]
        metrics_to_evaluate = ["rep_area", "rep_m_area", "gis_area", "gis_m_area", "no_tk_area"]
        metrics_dict = {"years": years}
        for metric in metrics_to_evaluate:
            metrics_dict[metric+"_name"] = metric
            metric_values = []
            for year in years:
                sql = f"SELECT SUM({metric}) FROM WDPA WHERE FromZ <= "
                sql += f"'{year}-01-01 00:00:00' AND ToZ > '{year}-01-01 00:00:00' "
                sql += " AND ISDELETED=0"
                cursor.execute(sql)
                rows = cursor.fetchall()
                val = (rows[0] and rows[0][0]) or 0
                metric_values.append(val)
            metrics_dict[metric] = metric_values
        PostgresExecutor.end_transaction()

        parcels = defaultdict(list)
        sql = "SELECT WDPA_ID, PARCEL_ID, FromZ, ToZ, IsDeleted FROM WDPA ORDER BY WDPA_ID, PARCEL_ID, FromZ"
        cursor.execute(sql)
        rows = cursor.fetchall()
        for row in rows:
            parcel_id = str(row[0]) + "_" + str(row[1])
            parcels[parcel_id].append({ "FromZ": row[2], "ToZ": row[3], "isDeleted": row[4]})

        historical_changes = []
        for start_year in [ 2017, 2018, 2019, 2020, 2021, 2022 ]:
            start_time = datetime(start_year, 1, 1, 0, 0, 0)
            end_time = datetime(start_year+1, 1, 1, 0, 0, 0)
            additions = 0
            deletions = 0
            number_updated = 0
            for parcel_id, changes in parcels.items():
                added = False
                deleted = False
                updated = 0
                first = True
                for change in changes:
                    # skip this record if it is outside the time range
                    if change["FromZ"] >= end_time or change["ToZ"] < start_time:
                        first = False
                        continue
                    if change["FromZ"] < start_time:
                        first = False
                        continue
                    if first:
                        added = True
                    elif change["isDeleted"]:
                        deleted = True
                    else:
                        updated += 1
                    first = False
                if added:
                    additions += 1
                if deleted:
                    deletions += 1
                number_updated += updated
            historical_changes.append((start_year, additions, deletions, number_updated))
        return render_template('ZAF_Metrics.html', **metrics_dict, historical_changes = historical_changes)


@app.route('/run_verifications', methods=['GET', 'POST'])
def run_verifications():
    metadata_id = request.args.get("metadataid")
    return jsonify(QAVerifier.verify(metadata_id))



@app.route('/metrics_for_countries', methods=['GET'])
def metrics_for_countries():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        start_time = time.time()
        countries_of_interest = [country[1].strip()for country in request.args.items("interest")]
        countries_of_interest_for_sql = ["'" + country + "'" for country in countries_of_interest]
        cursor = PostgresExecutor.begin_transaction(conn)
        years = [2017, 2018, 2019, 2020, 2021, 2022, 2023]
        metrics_to_evaluate = ["rep_area", "rep_m_area", "gis_area", "gis_m_area", "no_tk_area"]
        metrics_dict = {"years": years}
        for metric in metrics_to_evaluate:
            metrics_dict[metric+"_name"] = metric
            metric_values = []
            for year in years:
                sql = f"SELECT SUM({metric}) FROM WDPA a WHERE FromZ <= "
                sql += f" TIMESTAMP '{year}-06-01 00:00:00' AND ToZ > TIMESTAMP '{year}-06-01 00:00:00' "
                sql += " AND ISDELETED=0 AND EXISTS( SELECT 1 FROM WDPA_ISO_ASSOC b, ISO3 c "
                sql += f' WHERE b.CODE = c.CODE AND c.CODE IN ({",".join(countries_of_interest_for_sql)}) and a.WDPA_ID = b.WDPA_ID AND a.PARCEL_ID=b.PARCEL_ID)'
                cursor.execute(sql)
                rows = cursor.fetchall()
                val = (rows[0] and rows[0][0]) or 0
                metric_values.append(val)
            metrics_dict[metric] = metric_values
        PostgresExecutor.end_transaction()
    duration = time.time() - start_time
    print(f'Time taken was {duration}')
    return render_template('display_selected_country_metrics.html', **metrics_dict, selected_countries=",".join(countries_of_interest))

@app.route('/manage_schema')
def manage_schema():
    schemas = get_all_schemas()
    return render_template('manage_schema.html', all_schemas=schemas)


@app.route('/create_foundation')
def create_foundation():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        PostgresExecutor.begin_transaction(conn)
        MetadataCreator.execute()
        SqlRunner.execute('../sql/common_reference/ingestion_stages.sql')
        PostgresExecutor.end_transaction()
        return render_for_html(Logger.get_output())

@app.route('/create_reference_data')
def create_reference_data():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        PostgresExecutor.begin_transaction(conn)
        ReferenceDataSchemaPopulator.create_reference_data_schema("common")
        PostgresExecutor.end_transaction()
        return render_for_html(Logger.get_output())

@app.route('/load_reference_data')
def load_reference_data():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        try:
            PostgresExecutor.begin_transaction(conn)

            SqlRunner.execute('../sql/common_reference/iso3.sql')
            SqlRunner.execute('../sql/common_reference/iucn_cat.sql')
            SqlRunner.execute('../sql/common_reference/no_take.sql')
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
        return render_for_html(Logger.get_output())

@app.route("/promote_reference_data_action")
def promote_reference_data_action():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        executor = PostgresExecutor()
        executor.begin_transaction(conn)
        time_of_creation = request.args.get("time_of_creation")
        data_group = request.args.get("data_group")
        LoaderFromStagingToMain().ingest_standard(executor,[ 10000 ], ["iso3", "iucn_cat", "marine_enum"], time_of_creation, data_group)
        executor.end_transaction()
        return render_for_html(Logger.get_output())

def render_for_html(out_msg):
    return "<br>".join(out_msg) + '<br><br><div><a href="index">Back to Main Index</a>'

@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html')

@app.route('/create_staging_and_main')
def create_staging_and_main():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        try:
            PostgresExecutor.begin_transaction(conn)
            WDPASchemaPopulator.create_wdpa_schema("wdpa")
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
        return render_for_html(Logger.get_output())

@app.route('/load_quarantine_data')
def load_quarantine_data():
    return render_template('load_quarantine_data.html')


@app.route('/promote_reference_data')
def promote_reference_data():
    return render_template('promote_reference_data.html')


@app.route("/country_metrics")
def country_metrics():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT CODE, DESCRIPTION FROM ISO3 WHERE ToZ = TIMESTAMP '9999-01-01 00:00:00' ORDER BY Description")
        rows = cursor.fetchall()

        codes_and_descriptions = [[row[0],row[1]] for row in rows]
        return render_template('country_metrics.html', codes_and_descriptions=codes_and_descriptions)


@app.route('/load_quarantine_data_action')
def load_quarantine_data_to_staging():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        cursor = PostgresExecutor.begin_transaction(conn)
        cursor.execute('DELETE FROM STAGING_WDPA')
        cursor.execute('DELETE FROM STAGING_SPATIAL_DATA')
        cursor.execute('DELETE FROM STAGING_WDPA_ISO_ASSOC')
        cursor.execute('DELETE FROM STAGING_DATA_PROVIDERS')
        PostgresExecutor.end_transaction()
        table_name = request.args.get("tablename")
        translation_schema_name = request.args.get("translation_schema")
        driving_column = request.args.get("driving_column")
        time_of_creation = request.args.get("time_of_creation")
        data_group = request.args.get("data_group")
        if driving_column == "None":
            driving_column = None
        translator = QuarantineToStagingTranslator()
        translator.read_translation_schema('../json/' + translation_schema_name)
        try:
            translator.translate(table_name, driving_column, time_of_creation)
        except Exception as e:
            traceback.print_exc(limit=None, file=None, chain=True)
        return merge_staging_to_main_action(request)


@app.route('/create_source_table')
def create_source_table():
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        try:
            PostgresExecutor.begin_transaction(conn)
            WDPASchemaPopulator.create_source_schema("common")
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
        return render_for_html(Logger.get_output())

@app.route('/merge_staging')
def merge_staging_to_main():
    return render_template('merge_staging.html')

@app.route('/merge_staging_to_main')
def merge_staging_to_main_action(request):
    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
        time_of_creation = request.args.get("time_of_creation")
        parameters = {
            "WDPA Data": (["wdpa", "spatial_data", "wdpa_iso_assoc"], [], "wdpa"),
            "WDPA Source": (["data_providers"], [None], None )
        }
        data_group = request.args.get("data_group")
        if parameters.get(data_group):
            executor = PostgresExecutor()
            try:
                executor.begin_transaction(conn)
                parameters_to_use = parameters[data_group]
                LoaderFromStagingToMain().ingest_standard(executor,parameters_to_use[1], parameters_to_use[0], time_of_creation, data_group, parameters_to_use[2])
                executor.end_transaction()
                print(time_of_creation)
            except Exception as e:
                print(str(e))
                executor.rollback()
        else:
            Logger.get_logger().error(f"Data group {data_group} is unknown to the system")
        return render_for_html(Logger.get_output())


if len(sys.argv) == 2:
    port = int(sys.argv[1])
else:
    port = 8080
app.run(host='0.0.0.0', port=port)
