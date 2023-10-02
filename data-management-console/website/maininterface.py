# Contains the main functionality for all the operations performed by the services (this may be split out in future).
# Some example reports (which would really be part of the Ruby application) are also included for reference.
import gc
import os
import sys
import time
import traceback
from collections import defaultdict
from datetime import datetime
from pathlib import Path

from jinja2 import Template
import psycopg2
from filtering_logic.blockregistry import BlockRegistry
from filtering_logic.datablockfactory import DataBlockFactory
from filtering_logic.queryexceptions import InvalidTermException
from filtering_logic.selectionengine import SelectionEngine
from metadata_mgmt.metadatareader import MetadataReader
from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from runtime_mgmt.datagroupmanager import DataGroupManager
from schema_management.extractor import Extractor
from schema_management.schema_populator import SchemaPopulator
from schema_management.stagingdatapromoter import LoaderFromStagingToMain
from sql.sql_runner import SqlRunner
from translation.translation import QuarantineToStagingTranslator
from translation.translationerrormanager import TranslationException
from website.filterargshelper import FilterArgsHelper
from website.jsonexporter import JsonExporter


def get_all_schemas():
    with psycopg2.connect(connection_string()) as connection:
        cursor = connection.cursor()
        sql = "SELECT DISTINCT SchemaName FROM METADATA"
        cursor.execute(sql)
        rows = cursor.fetchall()
        return [row[0] for row in rows]


def south_africa_metrics(_):
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
        sql = "SELECT SITE_ID, PARCEL_ID, FromZ, ToZ, IsDeleted FROM WDPA ORDER BY site_ID, PARCEL_ID, FromZ"
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
        metrics_dict["historical_changes"] = historical_changes
        return render_template('ZAF_Metrics.html', metrics_dict)


def metrics_for_countries(request):
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
                sql += f"AND a.site_id = b.site_id and a.parcel_id = b.parcel_id "
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
    metrics_dict["selected_countries"] = ",".join(countries_of_interest)
    return render_template('display_selected_country_metrics.html', metrics_dict)


def create_foundation(request):
    #    with psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1") as conn:
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            cursor = executor.begin_transaction()
            SCHEMA_TO_POPULATE = 'foundation_tables'
            APP_SCHEMA_FILE = f'../json/{SCHEMA_TO_POPULATE}.json'
            app_schema_tables = list(Extractor.get_all_definitions(APP_SCHEMA_FILE, is_foundation=True))
            executor.code_tables(app_schema_tables, None, True, SCHEMA_TO_POPULATE,
                                 remove_metadata=False,
                                 add_objectid_index=False)  # foundation tables don't store their own metadata
            SqlRunner.execute(cursor, f'../sql/{SCHEMA_TO_POPULATE}/post_install.sql')
            return render_for_html(Logger.get_output())
        except Exception as ex:
            print(str(ex))
            traceback.print_exc(limit=None, file=None, chain=True)
            request.setResponseCode(400)
            return render_as_bytes({"error": str(ex)})
        finally:
            executor.end_transaction()


def uninstall_foundation(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            executor.begin_transaction()
            SchemaPopulator.drop_schema("foundation_tables",
                                        remove_metadata=False)  # this is the only case where we won't remove the metadata
            return render_for_html(Logger.get_output())
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            raise e
        finally:
            executor.end_transaction()


def create_reference_data(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            cursor = PostgresExecutor.begin_transaction()
            SchemaPopulator.create_schema('common_reference', cursor, is_reference_data=True)
            executor.end_transaction()
            cursor = executor.begin_transaction()
            SqlRunner.execute(cursor, '../sql/common_reference/post_install.sql')
            time_of_creation = '2000-01-01 00:00:00'
            data_group = "Reference Data"
            LoaderFromStagingToMain(data_group).ingest_standard(executor, time_of_creation,
                                                                DataGroupManager.tables(data_group))
            return render_for_html(Logger.get_output())
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            executor.rollback()
        finally:
            executor.end_transaction()


def uninstall_reference_data(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            executor.begin_transaction()
            SchemaPopulator.drop_schema("common_reference")
            return render_for_html(Logger.get_output())
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            executor.rollback()
            return str(e)
        finally:
            executor.end_transaction()


def render_for_html(out_msg):
    return render_as_bytes("<br>".join(out_msg) + '<br><br><div><a href="index">Back to Main Index</a>')


def render_as_bytes(bytes_in):
    raw_data = bytes(str(bytes_in), "utf-8")
    return raw_data


def load_file(file_name: str):
    full_path_name = os.getcwd() + "/" + file_name
    return Path(full_path_name).read_text()


def render_template(file_name: str, args: dict = {}):
    t = Template(load_file(f'templates/{file_name}'))
    ans_as_str = t.render(args)
    raw_data = bytes(ans_as_str, "utf-8")
    return raw_data


def return_home_page(_):
    return render_template('index.html', {})


def uninstall_wdpa(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            PostgresExecutor.begin_transaction()
            SchemaPopulator.drop_schema("wdpa")
            SchemaPopulator.drop_schema("wdpa_source")
            SchemaPopulator.drop_schema("wdpa_providers")
            SchemaPopulator.drop_schema("wdpa_reference")
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            PostgresExecutor.close_read_cursor()
    return render_for_html(Logger.get_output())


def install_wdpa(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            cursor = executor.begin_transaction()
            SqlRunner.execute(cursor, '../sql/wdpa/pre_install.sql')
            SchemaPopulator.create_schema("wdpa_reference", cursor, is_reference_data=True)
            executor.end_transaction()
            cursor = executor.begin_transaction()
            SchemaPopulator.create_schema("wdpa_providers", cursor)
            executor.end_transaction()
            cursor = executor.begin_transaction()
            SchemaPopulator.create_schema("wdpa_source", cursor)
            executor.end_transaction()
            cursor = executor.begin_transaction()
            SchemaPopulator.create_schema("wdpa", cursor)
            executor.end_transaction()
            cursor = executor.begin_transaction()
            SqlRunner.execute(cursor, '../sql/wdpa/post_install.sql')
            executor.end_transaction()

            executor.begin_transaction()
            time_of_creation = '2000-01-01 00:00:00'
            DataGroupManager.parameterize('../json/data_group.json')
            for data_group in ["WDPA Reference Data", "WDPA Providers", "WDPA Source"]:
                LoaderFromStagingToMain(data_group).ingest_standard(executor, time_of_creation,
                                                                    DataGroupManager.tables(data_group))
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            executor.end_transaction()
    return render_for_html(Logger.get_output())


def uninstall_pame(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            PostgresExecutor.begin_transaction()
            SchemaPopulator.drop_schema("pame")
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            PostgresExecutor.close_read_cursor()
    return render_for_html(Logger.get_output())


def install_pame(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            cursor = PostgresExecutor.begin_transaction()
            SqlRunner.execute(cursor, '../sql/pame/pre_install.sql')
            SchemaPopulator.create_schema("pame", cursor)
            SqlRunner.execute(cursor, '../sql/pame/post_install.sql')
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            PostgresExecutor.rollback()
        else:
            print("Successfully created")
            return render_for_html(Logger.get_output())
        finally:
            PostgresExecutor.end_transaction()


def uninstall_green_list(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            PostgresExecutor.begin_transaction()
            SchemaPopulator.drop_schema("green_list")
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            PostgresExecutor.close_read_cursor()
    return render_for_html(Logger.get_output())


def install_green_list(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            cursor = executor.begin_transaction()
            SqlRunner.execute(cursor, '../sql/green_list/pre_install.sql')
            SchemaPopulator.create_schema("green_list", cursor)
            SqlRunner.execute(cursor, '../sql/green_list/post_install.sql')
            executor.end_transaction()
            time_of_creation = '2000-01-01 00:00:00'
            DataGroupManager.parameterize('../json/data_group.json')
            data_group = "Green List Reference Data"
            LoaderFromStagingToMain(data_group).ingest_standard(executor, time_of_creation,
                                                                DataGroupManager.tables(data_group))
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            PostgresExecutor.rollback()
        else:
            print("Successfully created")
            return render_for_html(Logger.get_output())
        finally:
            PostgresExecutor.end_transaction()


def uninstall_icca(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            PostgresExecutor.begin_transaction()
            SchemaPopulator.drop_schema("icca")
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            PostgresExecutor.close_read_cursor()
    return render_for_html(Logger.get_output())


def install_icca(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            cursor = executor.begin_transaction()
            SqlRunner.execute(cursor, '../sql/icca/pre_install.sql')
            SchemaPopulator.create_schema("icca_reference", cursor, is_reference_data=True)
            executor.end_transaction()
            cursor = executor.begin_transaction()
            SchemaPopulator.create_schema("icca", cursor)
            SqlRunner.execute(cursor, '../sql/icca/post_install.sql')
            executor.end_transaction()
            time_of_creation = '2000-01-01 00:00:00'
            DataGroupManager.parameterize('../json/data_group.json')
            executor.begin_transaction()
            data_group = "ICCA Reference Data"
            LoaderFromStagingToMain(data_group).ingest_standard(executor, time_of_creation,
                                                                DataGroupManager.tables(data_group))
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            executor.rollback()
        else:
            print("Successfully created")
            return render_for_html(Logger.get_output())
        finally:
            executor.end_transaction()


def uninstall_icca_spatial(request):
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            cursor = executor.begin_transaction()
            SchemaPopulator.drop_schema("icca_spatial_data")
            executor.end_transaction()
        except Exception as ex:
            print(str(ex))
            traceback.print_exc(limit=None, file=None, chain=True)
            executor.rollback()
            request.setResponseCode(400)
            return render_as_bytes({"error": str(ex)})

        else:
            print("Successfully created")
            return render_for_html(Logger.get_output())
        finally:
            executor.end_transaction()


def install_icca_spatial(request):
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            cursor = executor.begin_transaction()
            SchemaPopulator.create_schema("icca_spatial_data", cursor)
            executor.end_transaction()
        except Exception as ex:
            print(str(ex))
            traceback.print_exc(limit=None, file=None, chain=True)
            executor.rollback()
            request.setResponseCode(400)
            return render_as_bytes({"error": str(ex)})
        else:
            print("Successfully created")
            return render_for_html(Logger.get_output())
        finally:
            executor.end_transaction()

def uninstall_demo(_):
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            PostgresExecutor.begin_transaction()
            SchemaPopulator.drop_schema("demo")
            PostgresExecutor.end_transaction()
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            PostgresExecutor.close_read_cursor()
    return render_for_html(Logger.get_output())


def install_demo():
    with psycopg2.connect(connection_string()) as conn:
        try:
            executor = PostgresExecutor()
            executor.set_connection(conn)
            cursor = executor.begin_transaction()
            '''            
            sql = "SELECT DISTINCT site_id, parcel_id FROM wdpa WHERE site_id < 100000"
            cursor.execute(sql)
            rows = cursor.fetchall()
            print(f'There were {len(rows)} rows')

            for table_name in ["crustaceans_may_2021","crustaceans_may_2023"]:
                cursor.execute(f"TRUNCATE TABLE {table_name}")
                for i in range(0, 100000):
                    name = f'Crustacean{i}'
                    url = f'www.democrustaceans.net/crustacean{i}.html'
                    index_wdpa = random.randrange(0, len(rows))
                    wdpa_id = rows[index_wdpa][0]
                    parcel_id = rows[index_wdpa][1]
                    count = random.randrange(0, 100000)
                    iso3 = ['BEL', 'GBE', 'ESP', 'AUT', 'ITA', 'CAN', 'AUT;ITA', 'ESP;ITA;AUT'][random.randrange(0, 8)]
                    case_study_published_id = random.randrange(0, 3)
                    case_study_published = ['0', '1', 'Pending'][case_study_published_id]
                    sql = f"INSERT INTO {table_name}(id, name,url,wdpa_id,parcel_id,count,iso3,case_study_published) VALUES("
                    sql += f"{i},'{name}','{url}',{wdpa_id},'{parcel_id}',{count},'{iso3}','{case_study_published}')"
                    cursor.execute(sql)
                print(f"{table_name} populated")
            executor.end_transaction()
            cursor = executor.begin_transaction()
            '''
            SchemaPopulator.create_schema("demo", cursor)
            executor.end_transaction()
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            executor.rollback()
        else:
            print("Successfully created")
            return render_for_html(Logger.get_output())
        finally:
            MetadataReader.tables(True)
            executor.end_transaction()


def clear_database():
    with psycopg2.connect(connection_string()) as conn:
        try:
            PostgresExecutor.set_connection(conn)
            cursor = PostgresExecutor.begin_transaction()
            sql = "SELECT distinct schemaname, tableowner, tablename FROM pg_catalog.pg_tables "
            sql += "WHERE schemaname = 'public' AND tablename <> 'spatial_ref_sys' "
            sql += " AND tablename NOT LIKE 'wdpadata%' AND tablename not LIKE 'green_list_m%' "
            sql += " AND tablename NOT LIKE 'pame_may%' AND tablename NOT LIKE 'zaf%' "
            sql += " AND tablename NOT LIKE 'icca_jun%' AND tablename NOT LIKE 'icca_aug%' ORDER BY tablename "
            cursor.execute(sql)
            tables_to_drop = []
            rows = cursor.fetchall()
            for row in rows:
                table_name = row[2]
                tables_to_drop.append(table_name)
            PostgresExecutor.end_transaction()
            cursor = PostgresExecutor.begin_transaction()
            for table_name in tables_to_drop:
                drop_sql = f'DROP TABLE IF EXISTS {table_name}'
                print(drop_sql)
                Logger.get_logger().info(drop_sql)
                cursor.execute(drop_sql)
            sql = "SELECT quote_ident(p.proname) as function FROM pg_catalog.pg_proc p "
            sql += "JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname not like 'pg%' "
            sql += "AND(CAST(p.proargnames as VARCHAR) LIKE '%code_in%' OR CAST(p.proargnames as VARCHAR) LIKE '%in_id%')"
            cursor.execute(sql)
            functions_to_drop = []
            rows = cursor.fetchall()
            for row in rows:
                function_name = row[0]
                functions_to_drop.append(function_name)
            PostgresExecutor.end_transaction()
            cursor = PostgresExecutor.begin_transaction()
            for function_name in functions_to_drop:
                drop_sql = f'DROP FUNCTION IF EXISTS {function_name}'
                print(drop_sql)
                Logger.get_logger().info(drop_sql)
                cursor.execute(drop_sql)
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
        finally:
            PostgresExecutor.end_transaction()
    return render_for_html(Logger.get_output())


def load_quarantine_data(request):
    return render_template('load_quarantine_data.html')


def country_metrics():
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.open_read_cursor()
        cursor.execute(
            "SELECT CODE, DESCRIPTION FROM ISO3 WHERE ToZ = TIMESTAMP '9999-01-01 00:00:00' ORDER BY Description")
        rows = cursor.fetchall()
        codes_and_descriptions = [[row[0], row[1]] for row in rows]
        PostgresExecutor.close_read_cursor()
        return render_template('country_metrics.html', {"codes_and_descriptions": codes_and_descriptions})


def fire_query(request):
    gc.enable()
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        filter_args = FilterArgsHelper.gather(request)
        filter_args.print_supplied_args()
        query_text = filter_args.get_arg("query_text")
        # query_text = "path=iso3[code='ESP'].wdpa.pame;iso3.wdpa.green_list&&fields=iso3:code,description&&fields=wdpa:site_id,parcel_id,name&&fields=pame:source_data_title&&fields=green_list:url&&timestamp=2026-06-28"
        try:
            tables = MetadataReader.tables()
            BlockRegistry.reset()
            # register each table name as a simple datablock
            # also register any association tables as associationdatablock
            for table in tables.keys():
                DataBlockFactory.create_simple_block(table)
                association_table_names, target_table_names = Extractor.extract_association_and_target_table_names(
                    table, tables)
                for association_table_name, target_table_name in zip(association_table_names, target_table_names):
                    # usually, for the forward order e.g. wdpa.iso3, we have the virtual columns
                    # most queries are of the backward form iso3[code='BEL'].wdpa.  This may not
                    DataBlockFactory.create_compound_block([table, target_table_name],
                                                           [association_table_name, target_table_name])
                    DataBlockFactory.create_compound_block([target_table_name, table], [association_table_name, table])
            se = SelectionEngine()
            output = JsonExporter.export(se.process_query(query_text))
            PostgresExecutor.rollback()
            return render_as_bytes(output)
        except InvalidTermException as ite:
            request.setResponseCode(400)
            return render_as_bytes({"error": str(ite)})
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            request.setResponseCode(400)
            return render_as_bytes({"error": str(e)})
        finally:
            # ensure we throw away all temporary tables
            PostgresExecutor.rollback()


def load_quarantine_data_to_staging(request):
    print("loading quarantine action")
    gc.enable()
    with psycopg2.connect(connection_string()) as conn:
        executor = PostgresExecutor()
        executor.set_connection(conn)
        filter_args = FilterArgsHelper.gather(request)
        filter_args.print_supplied_args()
        source_table_name = filter_args.get_arg("tablename")
        data_group = filter_args.get_arg("data_group")
        time_of_creation = filter_args.get_arg("time_of_creation")
        try:
            print("Translation phase")
            translator = QuarantineToStagingTranslator(data_group, time_of_creation)
            translator.translate(executor, source_table_name)
            print("Merge phase")
            LoaderFromStagingToMain(data_group).ingest_standard(executor, time_of_creation, translator.get_all_tables())
            print("Successfully merged")
            return render_for_html(Logger.get_output())
        except TranslationException as te:
            te.log_errors()
            return render_for_html(Logger.get_output())
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            return {"error": str(e)}, 400
        finally:
            PostgresExecutor.close_read_cursor()


def define_adhoc_query(_):
    return render_template('define_adhoc_query.html')


def view_metadata(request):
    with psycopg2.connect(connection_string()) as conn:
        PostgresExecutor.set_connection(conn)
        cursor = PostgresExecutor.open_read_cursor()
        try:
            sql = "SELECT distinct tablename, columnname, type FROM METADATA WHERE tablename NOT LIKE 'staging%' "
            sql += " AND columnname not in ('objectid','EffectiveFromZ', 'EffectiveToZ','FromZ','ToZ','ingestion_id','%id','id','IsDeleted') "
            sql += " AND type NOT IN ('PRIMARY KEY', 'FOREIGN KEY', 'FOREIGN KEY N') ORDER by tablename, columnname "
            cursor.execute(sql)
            entries = cursor.fetchall()
            return render_template('metadata.html', {"entries": entries})
        except Exception as e:
            return {"error": str(e)}, 400
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
