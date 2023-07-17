import gc
from collections import defaultdict
from datetime import datetime
import time
import traceback
from urllib.parse import quote

from flask import render_template, Flask, jsonify, request, redirect

from filtering_logic.selectionengine import SelectionEngine
from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from metadata_mgmt.metadata_creator import MetadataCreator
from schema_mgmt.referencedataschema import ReferenceDataSchemaPopulator
from schema_mgmt.stagingdatapromoter import LoaderFromStagingToMain
from qa.validation_checks import QAVerifier
from sql.sql_runner import SqlRunner
from schema_mgmt.schema_populator import SchemaPopulator
from translation.translation import QuarantineToStagingTranslator
import psycopg2
import sys

from runtime_mgmt.datagroupmanager import DataGroupManager
from translation.translationerrormanager import TranslationException
from website.filterargshelper import FilterArgsHelper

app = Flask(__name__)
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True


def get_all_schemas():
    with psycopg2.connect(connection_string()) as connection:
        cursor = connection.cursor()
        sql = "SELECT DISTINCT SchemaName FROM METADATA"
        cursor.execute(sql)
        rows = cursor.fetchall()
        return [row[0] for row in rows]


@app.route('/South_Africa_Metrics', methods=['GET'])
def metrics():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.open_read_cursor()
        years = [2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024]
        metrics_to_evaluate = ["rep_area", "rep_m_area", "gis_area", "gis_m_area", "no_tk_area"]
        metrics_dict = {"years": years}
        for metric in metrics_to_evaluate:
            metrics_dict[metric + "_name"] = metric
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
        PostgresExecutor.close_read_cursor()

        parcels = defaultdict(list)
        sql = "SELECT WDPA_ID, PARCEL_ID, FromZ, ToZ, IsDeleted FROM WDPA ORDER BY WDPA_ID, PARCEL_ID, FromZ"
        cursor.execute(sql)
        rows = cursor.fetchall()
        for row in rows:
            parcel_id = str(row[0]) + "_" + str(row[1])
            parcels[parcel_id].append({"FromZ": row[2], "ToZ": row[3], "isDeleted": row[4]})

        historical_changes = []
        for start_year in [2017, 2018, 2019, 2020, 2021, 2022]:
            start_time = datetime(start_year, 1, 1, 0, 0, 0)
            end_time = datetime(start_year + 1, 1, 1, 0, 0, 0)
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
        return render_template('ZAF_Metrics.html', **metrics_dict, historical_changes=historical_changes)


@app.route('/run_verifications', methods=['GET', 'POST'])
def run_verifications():
    metadata_id = request.args.get("metadataid")
    return jsonify(QAVerifier.verify(metadata_id))


@app.route('/metrics_for_countries', methods=['GET'])
def metrics_for_countries():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        start_time = time.time()
        countries_of_interest = [country[1].strip() for country in request.args.items("interest")]
        countries_of_interest_for_sql = ["'" + country + "'" for country in countries_of_interest]
        cursor = PostgresExecutor.open_read_cursor()
        years = [2019, 2020, 2021, 2022, 2023]
        metrics_to_evaluate = ["reported_area", "reported_marine_area", "gis_area", "gis_marine_area", "no_take_area"]
        metrics_dict = {"years": years}
        for metric in metrics_to_evaluate:
            metrics_dict[metric + "_name"] = metric
            metric_values = []
            for year in years:
                sql = f"SELECT sum({metric}) from wdpa a, wdpa_iso3_assoc b, iso3 c "
                sql += f'WHERE c.CODE IN ({",".join(countries_of_interest_for_sql)}) '
                sql += f"AND c.id = b.iso3_id AND b.FROMZ <= TIMESTAMP '{year}-06-01 00:00:00' "
                sql += f"AND b.ToZ >= TIMESTAMP '{year}-06-01 00:00:00' "
                sql += f"AND a.wdpa_id = b.wdpa_id and a.parcel_id = b.parcel_id "
                sql += f"AND a.FROMZ <= TIMESTAMP '{year}-06-01 00:00:00' AND a.ToZ >= TIMESTAMP '{year}-06-01 00:00:00' "
                try:
                    cursor.execute(sql)
                except Exception as e:
                    print(str(e))
                    traceback.print_exc(limit=None, file=None, chain=True)
                else:
                    rows = cursor.fetchall()
                    val = (rows[0] and rows[0][0]) or 0
                    metric_values.append(val)
            metrics_dict[metric] = metric_values
        PostgresExecutor.close_read_cursor()
    duration = time.time() - start_time
    print(f'Time taken was {duration}')
    return render_template('display_selected_country_metrics.html', **metrics_dict,
                           selected_countries=",".join(countries_of_interest))


@app.route('/manage_schema')
def manage_schema():
    schemas = get_all_schemas()
    return render_template('manage_schema.html', all_schemas=schemas)


@app.route('/create_foundation')
def create_foundation():
    #    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        try:
            cursor = PostgresExecutor.begin_transaction()
            MetadataCreator.execute()
            SqlRunner.execute('../sql/common_reference/ingestion_stages.sql', cursor)
            return render_for_html(Logger.get_output())
        except Exception as e:
            return str(e)
        finally:
            PostgresExecutor.end_transaction()


@app.route('/create_reference_data')
def create_reference_data():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        try:
            PostgresExecutor.begin_transaction()
            ReferenceDataSchemaPopulator.create_reference_data_schema("common")
            return render_for_html(Logger.get_output())
        except Exception as e:
            return str(e)
        finally:
            PostgresExecutor.end_transaction()


@app.route('/load_reference_data')
def load_reference_data():
    with psycopg2.connect(connection_string()) as conn:
        time_of_creation = '2000-01-01 00:00:00'
        data_group = "Reference Data"
        executor = PostgresExecutor()
        try:
            PostgresExecutor.set_connection(conn)
            cursor = PostgresExecutor.begin_transaction()
            SqlRunner.execute('../sql/common_reference/iso3.sql', cursor)
            SqlRunner.execute('../sql/common_reference/iucn_cat.sql', cursor)
            SqlRunner.execute('../sql/common_reference/no_take.sql', cursor)
            SqlRunner.execute('../sql/common_reference/green_list_status.sql', cursor)
            SqlRunner.execute('../sql/common_reference/designation_status.sql', cursor)
            SqlRunner.execute('../sql/common_reference/orig_designation_status.sql', cursor)
            SqlRunner.execute('../sql/common_reference/international_criteria.sql', cursor)
            SqlRunner.execute('../sql/common_reference/icca.sql', cursor)
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            executor.rollback()
        else:
            LoaderFromStagingToMain().ingest_standard(executor, time_of_creation, data_group)
            return render_for_html(Logger.get_output())
        finally:
            PostgresExecutor.end_transaction()


@app.route("/promote_reference_data_action")
def promote_reference_data_action():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        executor = PostgresExecutor()
        cursor = executor.open_read_cursor()
        time_of_creation = request.args.get("time_of_creation")
        new_description = request.args.get("new_desc")
        cursor.execute('DELETE FROM STAGING_IUCN_CAT')
        sql = f"INSERT INTO STAGING_IUCN_CAT(id, description, originator_id) VALUES(2, '{new_description}', 10000)"
        cursor.execute(sql)
        data_group = "Reference Data"
        LoaderFromStagingToMain().ingest_standard(executor, time_of_creation, data_group)
        executor.close_read_cursor()
        return render_for_html(Logger.get_output())


def render_for_html(out_msg):
    return "<br>".join(out_msg) + '<br><br><div><a href="index">Back to Main Index</a>'


@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html')


@app.route('/create_staging_and_main')
def create_staging_and_main():
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            cursor = PostgresExecutor.begin_transaction()
            SchemaPopulator.create_schema("wdpa", cursor)
            SchemaPopulator.create_schema("pame", cursor)
            SchemaPopulator.create_schema("green_list", cursor)
            SchemaPopulator.create_schema("icca", cursor)
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            PostgresExecutor.rollback()
        else:
            print("Successfully created")
            return render_for_html(Logger.get_output())
        finally:
            PostgresExecutor.end_transaction()


@app.route('/load_quarantine_data')
def load_quarantine_data():
    return render_template('load_quarantine_data.html')


@app.route('/promote_reference_data')
def promote_reference_data():
    return render_template('promote_reference_data.html')


@app.route("/country_metrics")
def country_metrics():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.open_read_cursor()
        cursor.execute(
            "SELECT CODE, DESCRIPTION FROM ISO3 WHERE ToZ = TIMESTAMP '9999-01-01 00:00:00' ORDER BY Description")
        rows = cursor.fetchall()
        codes_and_descriptions = [[row[0], row[1]] for row in rows]
        PostgresExecutor.close_read_cursor()
        return render_template('country_metrics.html', codes_and_descriptions=codes_and_descriptions)


@app.route('/fire_query')
def fire_query():
    print("Handling ad-hoc query")
    gc.enable()
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        filter_args = FilterArgsHelper.gather(request)
        filter_args.print_supplied_args()
        query_text = filter_args.get_arg("query_text")
        # query_text = "path=iso3[code='ESP'].wdpa.pame;iso3.wdpa.green_list&&fields=iso3:code,description&&fields=wdpa:wdpa_id,parcel_id,name&&fields=pame:source_data_title&&fields=green_list:url&&timestamp=2026-06-28"
        try:
            se = SelectionEngine()
            output = se.process_query(query_text)
            return output
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)

@app.route('/load_quarantine_data_action')
def load_quarantine_data_to_staging():
    print("loading quarantine action")
    gc.enable()
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        filter_args = FilterArgsHelper.gather(request)
        filter_args.print_supplied_args()
        source_table_name = filter_args.get_arg("tablename")
        data_group = filter_args.get_arg("data_group")
        cursor = PostgresExecutor.begin_transaction()
        DataGroupManager.parameterize('../json/data_group.json')
        for table in DataGroupManager.tables(data_group):
            sql = f"DELETE FROM STAGING_{table}"
            print(sql)
            cursor.execute(sql)
        PostgresExecutor.end_transaction()
        translation_schema = DataGroupManager.translation_schema(data_group)
        time_of_creation = filter_args.get_arg("time_of_creation")
        translator = QuarantineToStagingTranslator()
        try:
            translator.read_translation_schema('../json/' + translation_schema)
            translator.translate(source_table_name, data_group, time_of_creation)
        except TranslationException as te:
            te.log_errors()
            return render_for_html(Logger.get_output())
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            PostgresExecutor.close_read_cursor()
    return merge_staging_to_main_action(request)


@app.route('/create_source_table')
def create_source_table():
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            cursor = PostgresExecutor.begin_transaction()
            SqlRunner.execute('../sql/wdpa/wdpa_source.sql', cursor)
            SchemaPopulator.create_source_schema("common")
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            PostgresExecutor.close_read_cursor()
    return render_for_html(Logger.get_output())


@app.route('/merge_staging')
def merge_staging_to_main():
    return render_template('merge_staging.html')


@app.route('/define_adhoc_query')
def define_adhoc_query():
    return render_template('define_adhoc_query.html')


@app.route('/merge_staging_to_main')
def merge_staging_to_main_action(request):
    print("merging staging to main")
    with psycopg2.connect(connection_string()) as conn:
        time_of_creation = request.args.get("time_of_creation")
        data_group = request.args.get("data_group")
        executor = PostgresExecutor()
        try:
            PostgresExecutor.set_connection(conn)
            print(time_of_creation)
            LoaderFromStagingToMain().ingest_standard(executor, time_of_creation, data_group)
            print("Successfully merged")
            return render_for_html(Logger.get_output())
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            executor.rollback()
        finally:
            PostgresExecutor.close_read_cursor()


@app.route('/green_list')
def green_list():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.open_read_cursor()
        try:
            sql = "SELECT a.wdpa_id, a.parcel_id, b.description, a.url, a.expiry_date "
            sql += "from green_list a, green_list_status b "
            sql += "WHERE b.id = a.status_id"
            cursor.execute(sql)
            entries = cursor.fetchall()
            return render_template('green_list.html', entries=entries)
        except Exception as e:
            return str(e)
        finally:
            PostgresExecutor.close_read_cursor()


@app.route('/pame')
def pame():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.open_read_cursor()
        try:
            sql = "SELECT a.evaluation_id, a.wdpa_id, a.name, a.designation, a.methodology, a.source_data_title, a.source_year, a.year, a.url  from pame a"
            cursor.execute(sql)
            entries = cursor.fetchall()
            return render_template('pame.html', entries=entries)
        except Exception as e:
            return str(e)
        finally:
            PostgresExecutor.close_read_cursor()


@app.route('/icca')
def icca():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.open_read_cursor()
        try:
            sql = "SELECT a.icca_id, a.wdpa_id, a.parcel_id, a.original_name, a.local_name, a.latitude, a.longitude, a.creation_year, a.scope  from icca a"
            cursor.execute(sql)
            entries = cursor.fetchall()
            return render_template('icca.html', entries=entries)
        except Exception as e:
            return str(e)
        finally:
            PostgresExecutor.close_read_cursor()

@app.route('/view_metadata')
def view_metadata():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.open_read_cursor()
        try:
            sql = "SELECT distinct tablename, columnname, type FROM METADATA WHERE tablename NOT LIKE 'staging%' "
            sql += " AND columnname not in ('objectid','EffectiveFromZ', 'EffectiveToZ','FromZ','ToZ','ingestion_id','%id','id','IsDeleted') "
            sql += " AND type NOT IN ('PRIMARY KEY', 'CODE COLUMN', 'FOREIGN KEY') ORDER by tablename, columnname "
            cursor.execute(sql)
            entries = cursor.fetchall()
            return render_template('metadata.html', entries=entries)
        except Exception as e:
            return str(e)
        finally:
            PostgresExecutor.close_read_cursor()


def connection_string():
    connection_str = f"dbname={dbname} user={username} password={password} host={hostname}"
    print(connection_str)
    return connection_str


DataGroupManager.parameterize('../json/data_group.json')
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

app.run(host='0.0.0.0', port=port)
