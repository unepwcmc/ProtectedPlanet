import datetime

from schema_mgmt.ingestorconstants import IngestorConstants


class PostgresConverter:
    @staticmethod
    def code_column(name, data_type):
        return f'{name} {data_type}'

    @staticmethod
    def code_foreign_key(source_columns, target_table, target_columns):
        source = ",".join(source_columns)
        target = ",".join(target_columns)
        return f'CONSTRAINT fk_name FOREIGN_KEY({source}) REFERENCES {target_table}({target})'

    @staticmethod
    def code_primary_key(columns):
        primary_key_fields = ",".join(columns)
        return f' PRIMARY KEY({primary_key_fields})'

    @staticmethod
    def fully_qualified_table_name(table_name, area):
        if area is not None:
            table_name = area + "_" + table_name
        return table_name

    @staticmethod
    def code_table(_, table, area):
        return f'CREATE TABLE {PostgresConverter.fully_qualified_table_name(table.name, area)} ({",".join(table.convert(PostgresConverter()))})'

    @staticmethod
    def drop_table(_, table, area):
        return f'DROP TABLE IF EXISTS {PostgresConverter.fully_qualified_table_name(table.name, area)}'

    @staticmethod
    def store_metadata(schema, table, area):
        sql = []
        for el in table.elements:
            element_value = el.metadata()
            element_value = (
                PostgresConverter.fully_qualified_table_name(element_value[0], area), element_value[1],
                element_value[2],
                element_value[3])
            command = f"INSERT INTO METADATA(SchemaName, TableName, ColumnName, Type, KeyColumns) VALUES('{schema}', '{element_value[0]}', '{element_value[1]}', '{element_value[2]}', '{element_value[3]}')"
            sql.append(command)
        return sql

    @staticmethod
    def get_staging_data_originators(driving_table):
        return f"SELECT DISTINCT originator_id FROM staging_{driving_table}"

    @staticmethod
    def clear_metadata_for_this_table(schema, table, area):
        return f"DELETE FROM metadata WHERE schemaname='{schema}' AND tablename='{PostgresConverter.fully_qualified_table_name(table.name, area)}'"

    @staticmethod
    def create_objectid_index(_, table, area):
        return f"CREATE UNIQUE INDEX ON {PostgresConverter.fully_qualified_table_name(table.name, area)} (objectid)"

    @staticmethod
    def comparison_clause(col, is_foreign_key):
        col_type = col.data_type.lower()
        # auto-generated ones should be automatically true as it's OK for these
        # non-business types to have different values
        # this clause needs to go first otherwise INT GENERATED DEFAULT .... will look like int
        if "uuid" in col_type or "serial" in col_type or "generated" in col_type:
            return ""
        # now check for foreign keys - these will be int's but must match (no tolerance applicable)
        if is_foreign_key:
            return f"a.{col.name} = b.{col.name}"
        # genuine business data types
        if "char" in col_type or "date" in col_type or "timestamp" in col_type:
            return f"CASE WHEN a.{col.name} is not NULL and b.{col.name} is NOT NULL THEN CAST(a.{col.name} = b.{col.name} AS BOOLEAN) WHEN a.{col.name} IS NULL and b.{col.name} IS NULL THEN CAST(1 AS BOOLEAN) ELSE CAST(0 AS BOOLEAN) END"
        if "int" in col_type or "double" in col_type or "float" in col_type:
            # set the value to just enough to indicate there's a change without danger of a numerical overflow
            return f"CASE WHEN a.{col.name} is not NULL and b.{col.name} is NOT NULL THEN abs(a.{col.name}-b.{col.name}) WHEN a.{col.name} IS NULL and b.{col.name} IS NULL THEN 0 ELSE 10000 END"
        if "geom" in col_type:
            return f"CASE WHEN a.{col.name} is not NULL and b.{col.name} is NOT NULL THEN CAST(CAST(a.{col.name} as text) = CAST(b.{col.name} as text) AS INT) WHEN a.{col.name} IS NULL and b.{col.name} IS NULL THEN 0 ELSE 10000 END"
        raise Exception("Need more equality clauses")

    @staticmethod
    def construct_query_clause(quarantine_table, target_table, originator_id, closed_universe):
        # start with the Equal and Update cases
        where_clause_elements = []
        target_positions = {}
        quarantine_positions = {"objectid": 0}
        position = 1

        # create the common where clause based on the PK
        for PK in quarantine_table.primary_key().column_names.split(","):
            where_clause_elements.append(f" a.{PK}=b.{PK} ")

        main_clause_for_update_columns = ["a.objectid"]
        foreign_key_dictionary = {}
        FKs = quarantine_table.foreign_keys()
        for FK in FKs:
            for col_name in FK.source_columns:
                foreign_key_dictionary[col_name] = True

        for col in quarantine_table.columns():
            comp_clause = PostgresConverter.comparison_clause(col, col.name in foreign_key_dictionary)
            if comp_clause:
                main_clause_for_update_columns.append(comp_clause)
                quarantine_positions[col.name] = position
                position += 1
        main_clause_for_update_columns.append("b.objectid")
        target_positions["objectid"] = position
        main_clause_for_update_columns.append("'UPDATE'")

        main_clause_for_update = f'SELECT {", ".join(main_clause_for_update_columns)} FROM {quarantine_table.name} a JOIN {target_table.name} b '
        where_clause_for_update = " ON " + " and ".join(where_clause_elements)
        main_clause_for_update += where_clause_for_update
        if originator_id != IngestorConstants.WCMC_SPECIAL_PROVIDER_ID:
            main_clause_for_update += f" AND a.ORIGINATOR_ID={originator_id} "
        main_clause_for_update += " AND b.ToZ=TIMESTAMP '9999-01-01 00:00:00'"

        main_clause_for_addition_columns = ["a.objectid"]
        for _ in range(len(quarantine_positions)-1):
            main_clause_for_addition_columns.append("NULL")
        #no objectid in the main table
        main_clause_for_addition_columns.append("NULL")
        main_clause_for_addition_columns.append("'ADD'")

        main_clause_for_addition = f'SELECT {", ".join(main_clause_for_addition_columns)} FROM {quarantine_table.name} a WHERE '
        if originator_id != IngestorConstants.WCMC_SPECIAL_PROVIDER_ID:
            main_clause_for_addition += f" a.ORIGINATOR_ID={originator_id} AND "
        main_clause_for_addition += f" NOT EXISTS (SELECT 1 FROM {target_table.name} b WHERE " + " AND ".join(
            where_clause_elements)
        main_clause_for_addition += f" AND b.ToZ=TIMESTAMP '9999-01-01 00:00:00') "

        main_clause_for_deletion_columns = ["NULL"]
        for _ in range(len(quarantine_positions)-1):
            main_clause_for_deletion_columns.append("NULL")
        main_clause_for_deletion_columns.append("b.objectid")
        main_clause_for_deletion_columns.append("'DELETED'")
        main_clause_for_deletion = f'SELECT {", ".join(main_clause_for_deletion_columns)} FROM {target_table.name} a WHERE '
        # if we have a closed universe (during migration), we know we have enough information to determine whether the record
        # has been moved to another provider, so don't filter by originator
        # when the universe is not closed (a single data provider's information is arriving), we should not delete (as of current knowledge)
        main_clause_for_deletion += " AND a.ToZ=TIMESTAMP '9999-01-01 00:00:00' AND a.ISDELETED=0 "
        main_clause_for_deletion += f" AND NOT EXISTS (SELECT 1 FROM {quarantine_table.name} b "
        main_clause_for_deletion += ' WHERE ' + " and ".join(where_clause_elements)
        if not closed_universe and originator_id is not None:
            main_clause_for_deletion += f" AND b.ORIGINATOR_ID={originator_id}"
        main_clause_for_deletion += ")"
        main_clause = " UNION ".join([main_clause_for_addition, main_clause_for_update])

        return main_clause, quarantine_positions, target_positions

    @staticmethod
    def count_as_of(target_table, time_of_interest):
        sql = f"SELECT COUNT(1), SUM(IsDeleted) FROM {target_table.name} WHERE FromZ <= '{time_of_interest}' AND ToZ > '{time_of_interest}' "
        sql += f" AND EffectiveFromZ <='{time_of_interest}' AND EffectiveToZ > '{time_of_interest}'"
        return sql

    @staticmethod
    def get_time_from_database():
        return "SELECT now()::timestamp(0)"

    @staticmethod
    def load_keys(lookup_table, lookup_column, code_column, time_of_creation):
        sql = f"SELECT {code_column}, {lookup_column} from {lookup_table} WHERE FromZ <= TIMESTAMP '{time_of_creation}' AND ToZ > TIMESTAMP '{time_of_creation}'"
        return sql

    @staticmethod
    def get_originator_column_name():
        return "ORIGINATOR_ID"

    @staticmethod
    def get_quarantine_data_by_driving_column(driving_table, driving_column):
        return f'SELECT DISTINCT {driving_column} FROM {driving_table}'

    @staticmethod
    def get_rows_for_given_driver_column_value(input_columns, originator_id, driving_table, driving_column):
        sql = f"SELECT {','.join(input_columns.keys())} FROM {driving_table} "
        if driving_column:
            sql += f" WHERE {driving_column}={originator_id}"
        return sql

    @staticmethod
    def construct_sql_to_store(target_table, vals_to_store):
        if len(vals_to_store) == 0:
            return None
        cols_to_store = ",".join(vals_to_store[0].keys())
        sql = f"INSERT INTO staging_{target_table} ({cols_to_store}) VALUES"
        sub_sqls = []
        for val_to_store in vals_to_store:
            sub_sql = "("
            vals_to_insert = []
            for col, val in val_to_store.items():
                if isinstance(val, (int, float)):
                    vals_to_insert.append(str(val))
                elif isinstance(val, str):
                    vals_to_insert.append("'" + str(val).replace("'", "''") + "'")
                elif isinstance(val, datetime.date):
                    vals_to_insert.append("'" + val.strftime('%Y-%m-%d') + "'")
                else:
                    vals_to_insert.append('NULL')

            sub_sql += ",".join(vals_to_insert) + ")"
            sub_sqls.append(sub_sql)
        sql = sql + ",".join(sub_sqls)
        return sql

    @staticmethod
    def delete_staging_rows(table_def):
        return f"DELETE FROM {table_def.name}"
