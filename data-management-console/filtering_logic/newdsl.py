import datetime
from typing import Any

from filtering_logic.datablock import DataBlock, AssociationDataBlock
from metadata_mgmt.metadatareader import MetadataReader
from postgres.postgresexecutor import PostgresExecutor
from schema_management.tableexceptions import ColumnByNameException
from schema_management.tables import TableDefinition, VirtualColumn
from translation.foreignkeyhandler import ForeignKeyHandler

processed_blocks = {}
all_tables_by_objectid = {}

DATA_BLOCK_AT_THIS_LEVEL = "."
SENTINEL_DATETIME = datetime.datetime(1970, 1, 1, 0, 0, 0)


def transformed_view_name(name: str):
    return name + "_v"


def translate_individual_part(field: str, master_timestamp, master_as_of) -> str:
    all_tables = MetadataReader.tables()
    parts = field.split(".")
    table_data: TableDefinition = all_tables[parts[0]]
    column_info = table_data.column_by_name(parts[1])
    if isinstance(column_info, VirtualColumn):
        print(f'Field is {field}')
        print(column_info.function_to_call)
        function_prototype = column_info.function_to_call
        function_prototype = function_prototype.replace('update_time', f"TIMESTAMP '{master_timestamp}'")
        function_prototype = function_prototype.replace('as_of', f"TIMESTAMP '{master_as_of}'")
        return function_prototype
    return field


def create_views(path_to_process: list[DataBlock], master_timestamp, master_as_of, cursor):
    for block in path_to_process:
        if processed_blocks.get(block.name()):
            continue
        if isinstance(block, AssociationDataBlock):
            create_views([block.first_block], master_timestamp, master_as_of, cursor)
            create_views([block.second_block], master_timestamp, master_as_of, cursor)
            continue
        else:
            sql = f'CREATE TEMPORARY VIEW {transformed_view_name(block.name())} AS SELECT * '
            sql += f' FROM {block.name()} '
            if len(block.where_clause()):
                reassembled_parts = []
                parts = block.where_clause().split(' ')
                for part in parts:
                    if part.startswith(block.name() + "."):
                        reassembled_parts.append(translate_individual_part(part, master_timestamp, master_as_of))
                    else:
                        reassembled_parts.append(part)
                sql += ' WHERE ' + " ".join(reassembled_parts)
                connector = " AND "
            else:
                connector = " WHERE "
            sql += connector + f" {block.name()}.FromZ <= TIMESTAMP '{master_timestamp}' AND {block.name()}.ToZ > TIMESTAMP '{master_timestamp}' AND {block.name()}.EffectiveFromZ <= TIMESTAMP '{master_as_of}' AND {block.name()}.EffectiveToZ > TIMESTAMP '{master_as_of}'"
        print(sql)
        cursor.execute(sql)
        processed_blocks[block.name()] = True


def translate_virtual_fields(all_fields, master_timestamp, master_as_of):
    # if it's a calculated or a foreign key field, handle it here
    translated_fields = []
    for field in all_fields:
        translated_fields.append(translate_individual_part(field, master_timestamp, master_as_of))
    return translated_fields


def create_sql(path_to_process: list[DataBlock], master_timestamp, master_as_of):
    all_fields = []
    all_tables = []
    where_conditions = []
    cardinalities = []
    field_ranges = []
    predecessor = None
    for mapped_block in list(zip('abcdefghij', path_to_process)):
        block_to_process = mapped_block
        if isinstance(mapped_block[1], AssociationDataBlock):
            # the association table will contribute no fields
            alias = mapped_block[0]+"_al"
            first_block = block_to_process[1].first_block
            all_tables.append(f'{transformed_view_name(first_block.name())} {alias}')
            (backward_keys, forward_keys, _) = ForeignKeyHandler.get_relationship(
                predecessor[1].name(), first_block.name())
            assert (len(backward_keys) == len(forward_keys))
            corresponding_keys = list(zip(backward_keys, forward_keys))
            for backward_key, forward_key in corresponding_keys:
                backward_key = backward_key.replace(first_block.name() + ".", alias + ".")
                backward_key = backward_key.replace(predecessor[1].name() + ".", predecessor[0] + ".")
                forward_key = forward_key.replace(first_block.name() + ".", alias + ".")
                forward_key = forward_key.replace(predecessor[1].name() + ".", predecessor[0] + ".")
                where_conditions.append(f' {backward_key} = {forward_key} ')
            # the fields are held on
            block_to_process[1].second_block.add_fields_and_table(first_block.fields())
            block_to_process[1].second_block.add_where_clause(first_block.where_clause())
            block_to_process =  (mapped_block[0], block_to_process[1].second_block)
            predecessor = (alias, first_block)
        fields_wanted = [f'{block_to_process[0]}.objectid', f'{block_to_process[0]}.fromz', f'{block_to_process[0]}.effectivefromz']
        fields_wanted += translate_virtual_fields(block_to_process[1].fields(), master_timestamp, master_as_of)
        field_ranges.append((len(all_fields), len(all_fields) + len(fields_wanted)))
        all_fields += [f'{field.replace(block_to_process[1].name() + ".", block_to_process[0] + ".")} ' for field in
                       fields_wanted]
        all_tables.append(f'{transformed_view_name(block_to_process[1].name())} {block_to_process[0]}')
        if predecessor is not None:
            # determine the relationship between the tables
            (backward_keys, forward_keys, is_one_to_one) = ForeignKeyHandler.get_relationship(
                predecessor[1].name(), block_to_process[1].name())
            cardinalities.append(is_one_to_one)
            assert (len(backward_keys) == len(forward_keys))
            corresponding_keys = list(zip(backward_keys, forward_keys))
            for backward_key, forward_key in corresponding_keys:
                # be wary of things like predecessor = icca and this table is icca_spatial_data
                backward_key = backward_key.replace(block_to_process[1].name() + ".", block_to_process[0] + ".")
                backward_key = backward_key.replace(predecessor[1].name() + ".", predecessor[0] + ".")
                forward_key = forward_key.replace(block_to_process[1].name() + ".", block_to_process[0] + ".")
                forward_key = forward_key.replace(predecessor[1].name() + ".", predecessor[0] + ".")
                where_conditions.append(f' {backward_key} = {forward_key} ')
        predecessor = block_to_process
    sql = "SELECT " + ",".join(all_fields) + " FROM " + ",".join(all_tables)
    if len(where_conditions):
        sql += " WHERE " + " AND ".join(where_conditions)
    return sql, cardinalities, field_ranges


def get_raw_data(sql, field_ranges, cursor) -> dict:
    cursor.execute(sql)
    rows = cursor.fetchall()
    top_level_dict = {}
    for row in rows:
        this_level_dict = top_level_dict
        for field_range in field_ranges:
            obj = row[field_range[0]:field_range[1]]
            if this_level_dict.get(obj) is None:
                this_level_dict[obj] = {}
            this_level_dict = this_level_dict[obj]
    return top_level_dict


def lookup_or_create(block_name:str, objectid: int, row_entries:dict):
    if all_tables_by_objectid.get(block_name) is None:
        all_tables_by_objectid[block_name] = {}
    this_row = all_tables_by_objectid[block_name].get(objectid)
    if this_row is None:
        this_row = row_entries.copy()
        all_tables_by_objectid[block_name][objectid] = this_row
    else:
        this_row = this_row
    return this_row

def turn_raw_data_into_chains(raw_data: dict, cardinalities: list, path_to_process: list[DataBlock]) -> tuple[
    list[dict], int | Any]:
    retval = []
    latest_change = SENTINEL_DATETIME
    current_block_name = ''
    for key, value in raw_data.items():
        current_block = path_to_process[0]
        if isinstance(current_block, AssociationDataBlock):
            current_block_name = current_block.second_block.name()
            fields = current_block.first_block.fields()
        else:
            current_block_name = current_block.name()
            fields = current_block.fields()
        field_names = [field.replace(current_block_name + ".", "") for field in
                       fields]  # just want the field name not the table name
        # put the latest_change in there too
        objectid, fromz, effectivefromz = key[0:3]
        this_row = lookup_or_create(current_block_name, objectid, dict(zip(field_names, key[3:])))
        latest_change = max(latest_change, fromz, effectivefromz)
        if len(value):
            lower_level_as_chain, latest_change, lower_block_name = turn_raw_data_into_chains(value, cardinalities[1:],
                                                                            path_to_process[1:])
            if cardinalities[0] == False:  # 1 to Many
                this_row[lower_block_name] = lower_level_as_chain
            else:
                this_row[lower_block_name] = lower_level_as_chain[0]
        retval.append(this_row)
    return retval, latest_change, current_block_name


def process_path(path_to_process: list[DataBlock], master_timestamp, master_as_of, cursor) -> tuple[
    list[dict], int | Any]:
    try:
        create_views(path_to_process, master_timestamp, master_as_of, cursor)
        sql, cardinalities, field_ranges = create_sql(path_to_process, master_timestamp, master_as_of)
        raw_data = get_raw_data(sql, field_ranges, cursor)
        result_data, latest_change, _ = turn_raw_data_into_chains(raw_data, cardinalities, path_to_process)
        return result_data, latest_change
    except ColumnByNameException as cbn:
        err_msg = {"column error": str(cbn)}
        print(err_msg)
        return ([err_msg], 0)
    except Exception as e:
        err_msg = {"general error": str(e)}
        print(err_msg)
        return ([err_msg], 0)

def process_recursively(current_block_path: list, next_steps: dict, master_timestamp, master_as_of, cursor):
    if len(next_steps) == 1:
        path_to_process = current_block_path + [next_steps[DATA_BLOCK_AT_THIS_LEVEL]]
        print(f'Got a path of length {len(path_to_process)}')
        assert (len(path_to_process) < 10)
        return process_path(path_to_process, master_timestamp, master_as_of, cursor)
    else:
        result_data = None
        latest_change = None
        for block_name, further_steps in next_steps.items():
            if block_name == DATA_BLOCK_AT_THIS_LEVEL:
                continue
            result_data, latest_change = process_recursively(current_block_path + [next_steps[DATA_BLOCK_AT_THIS_LEVEL]], further_steps,
                                                             master_timestamp, master_as_of, cursor)
        return result_data, latest_change


def process_new_dsl(chain: dict, master_timestamp, master_as_of, master_offset, master_limit):
    if master_timestamp is None:
        master_timestamp = '9998-01-01'
    # check there's only one object in the head - otherwise we have multiple chains we cannot join
    assert (len(chain) == 1)
    processed_blocks.clear()
    all_tables_by_objectid.clear()
    # first, split into all paths
    executor = PostgresExecutor()
    cursor = executor.begin_transaction()
    latest_change = 1
    result_data = {}
    for head, steps in chain.items():
        result_data, latest_change = process_recursively([], steps, master_timestamp, master_as_of, cursor)
    max_rows_retrievable = len(result_data)
    result_data = result_data[master_offset:master_offset+master_limit]
    executor.end_transaction()
    return {"data": result_data,
            "max_rows": max_rows_retrievable,
            "latest_change": latest_change}


