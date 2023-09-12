import traceback
from collections import defaultdict
from functools import reduce

from filtering_logic.blockregistry import BlockRegistry
from filtering_logic.chaintable import ChainTable
from filtering_logic.datablock import AssociationDataBlock, DataBlock
from filtering_logic.queryexceptions import RelationshipException
from schema_management.tableexceptions import ColumnByNameException
from translation.foreignkeyhandler import ForeignKeyHandler


class ExecutionChain:
    DATA_BLOCK_AT_THIS_LEVEL = "."

    def __init__(self):
        self._chain = {}
        self._blocks_referenced = {}

    def add_block(self, chain_items: list, data_block):
        if len(chain_items) == 0:
            raise RuntimeError("Adding data block to root is not allowed")
        self.add_chain_item(self._chain, chain_items[0], chain_items[1:], data_block)

    def add_chain_item(self, dict_obj, head_item, tail_items, data_block):
        if not tail_items:
            # don't put it in again if it already exists
            if head_item not in dict_obj:
                # use a special sentinel to indicate we have walked the chain
                # there should be one and only one of these special sentinels at each level
                dict_obj[head_item] = {ExecutionChain.DATA_BLOCK_AT_THIS_LEVEL: data_block}
            return
        else:
            if dict_obj.get(head_item) is None:
                dict_obj[head_item] = {}
            self.add_chain_item(dict_obj[head_item], tail_items[0], tail_items[1:], data_block)

    def get_block(self, chain_items: list):
        if len(chain_items) == 0:
            return None
        self.get_chain_item(self._chain, chain_items[0], chain_items[1:])

    def get_block_for_name(self, table_name, fully_qualified_table_name):
        if self._blocks_referenced.get(table_name):
            return self._blocks_referenced[table_name]
        data_block: AssociationDataBlock = BlockRegistry.get_compound_block_for_name(fully_qualified_table_name)
        if data_block is None:
            data_block_simple: DataBlock = BlockRegistry.get_block_for_name(table_name)
            self._blocks_referenced[table_name] = data_block_simple
            return data_block_simple
        else:
            reference_data_block = data_block.first_block
            self._blocks_referenced[table_name] = reference_data_block
            return data_block

    def get_chain_item(self, dict_obj, head_item, tail_items):
        val = dict_obj.get(head_item)
        if val is None:
            return None
        if tail_items:
            return self.get_chain_item(dict_obj[head_item], tail_items[0], tail_items[1:])
        return val

    def construct_chain(self, master_timestamp, master_as_of, master_offset, master_limit):
        val = list(self._chain.values())[0]
        if master_timestamp is None:
            master_timestamp = '9998-01-01'
        try:
            top_level_chaintable = self.construct_chain_recursive(val, None, [], [], master_timestamp,
                                                                  master_as_of,
                                                                  master_offset, master_limit)
            result_data_as_dict = list(top_level_chaintable.forward_results().values())
            result_data = []
            for data in result_data_as_dict:
                for _, val in data.items():
                    result_data.append(val)
            return {"data": result_data,
                    "max_rows": top_level_chaintable.max_rows_retrievable()}
        except ColumnByNameException as cbn:
            return {"column error": str(cbn)}
        except Exception as e:
            return {"general error": str(e)}

    def construct_chain_recursive(self, chain: dict, prior, forward_keys_from_higher_level,
                                  backward_keys_for_mapping, master_timestamp, master_as_of,
                                  master_offset, master_limit) -> ChainTable:
        # walk the chain of datablocks from the root, joining them up as you go
        # at each level get the root item, evaluate it and then chain everything else at this level from it
        block_at_this_level = chain[ExecutionChain.DATA_BLOCK_AT_THIS_LEVEL]
        try:
            if isinstance(block_at_this_level, AssociationDataBlock):
                association_block = block_at_this_level.first_block
                main_table_data_block = block_at_this_level.second_block
                association_streamer = association_block.streamer()

                #                (backward_keys, forward_keys, is_one_to_one) = ForeignKeyHandler.get_relationship(
                #                    association_block.name()
                #                    , main_table_data_block.name())

                association_keys_for_mapping = {main_table_data_block.name(): ["wdpa_iso3_iso3.site_id", "wdpa_iso3_iso3.parcel_id"]}
                association_chaintable: ChainTable = association_streamer.chain(prior,
                                                                                ["wdpa_iso3_iso3.id"],
                                                                                association_keys_for_mapping,
                                                                                ["iso3.id"],
                                                                                [],
                                                                                association_block.name(),
                                                                                block_at_this_level.where_clause(),
                                                                                master_timestamp,
                                                                                master_as_of, master_offset,
                                                                                master_limit)
                main_table_streamer = main_table_data_block.streamer()
                backward_key_set = {}
                forward_key_set = {}
                is_one_to_one_set = {}
                lower_levels_blocks = {key: value for key, value in chain.items() if
                                       key != ExecutionChain.DATA_BLOCK_AT_THIS_LEVEL}

                for lower_level_block_key in lower_levels_blocks.keys():
                    (backward_keys, forward_keys, is_one_to_one) = ForeignKeyHandler.get_relationship(
                        block_at_this_level.name(), lower_level_block_key)
                    backward_key_set[lower_level_block_key] = backward_keys
                    forward_key_set[lower_level_block_key] = forward_keys
                    is_one_to_one_set[lower_level_block_key] = is_one_to_one

                main_table_chaintable: ChainTable = main_table_streamer.chain(association_chaintable,
                                                                              ["wdpa.site_id", "wdpa.parcel_id"],
                                                                              backward_key_set,
                                                                              ["wdpa.site_id", "wdpa.parcel_id"],
                                                                              #main_table_data_block.fields(),
                                                                              ["wdpa.site_id", "wdpa.parcel_id", "wdpa.name"],
                                                                              main_table_data_block.name(),
                                                                              "", master_timestamp,
                                                                              master_as_of, master_offset, master_limit)

                for lower_level_block_key, lower_level_block_value in lower_levels_blocks.items():
                    forward_keys_for_lower_level = forward_key_set[lower_level_block_key]
                    backward_keys_for_lower_level = backward_key_set[lower_level_block_key]
                    if forward_keys_for_lower_level is None:
                        err_msg = f'No relationship defined for {lower_level_block_key}'
                        raise RelationshipException(err_msg)

                    lower_level_table = self.construct_chain_recursive(lower_level_block_value,
                                                                       association_chaintable,
                                                                       forward_keys_for_lower_level,
                                                                       backward_keys_for_lower_level, master_timestamp,
                                                                       master_as_of, 0, 1000000)
                    back_res = main_table_chaintable.backward_results()
                    for forward_key, value in lower_level_table.forward_results().items():
                        parent_object_keys = back_res.get(forward_key)
                        for parent_obj_key in parent_object_keys:
                            parent_obj = main_table_chaintable.forward_results().get(parent_obj_key)
                            if parent_obj.get(lower_level_block_key) is None:
                                parent_obj[lower_level_block_key] = [value]
                            else:
                                parent_obj[lower_level_block_key].append(value)

                lower_level_block_key = main_table_data_block.name()

                print("Completing Compound Data")
                back_res = association_chaintable.backward_results()[lower_level_block_key]
                row_number_to_upper_level = association_chaintable.row_number_to_upper_level()
                for forward_key, value in main_table_chaintable.forward_results().items():
                    # forward key from below is this level's row number
                    collected_forward_row_number_for_this_table = row_number_to_upper_level[forward_key]
                    parent_object_keys = association_chaintable.forward_results().get(
                        collected_forward_row_number_for_this_table)
                    parent_obj = parent_object_keys[forward_key]
                    value = list(value.values())
                    if parent_obj.get(lower_level_block_key) is None:
                        parent_obj[lower_level_block_key] = value[0]
                    else:
                        parent_obj[lower_level_block_key].append(value)

                # now need to walk through the forwrd results and "lift" the result one level to
                # hide the fact that the association is done in 2 steps
                association_chaintable.compress_forward_results_one_level()
                return association_chaintable
            # simple data here
            else:
                streamer = block_at_this_level.streamer()
                # get all the keys we shall need to join to further chain elements through foreign key relationships
                # in this way, there is a set of backward keys, indexed by the name of the table.
                lower_levels_blocks = {key: value for key, value in chain.items() if
                                       key != ExecutionChain.DATA_BLOCK_AT_THIS_LEVEL}
                backward_key_set = {}
                forward_key_set = {}
                is_one_to_one_set = {}
                for lower_level_block_key in lower_levels_blocks.keys():
                    (backward_keys, forward_keys, is_one_to_one) = ForeignKeyHandler.get_relationship(
                        block_at_this_level.name(), lower_level_block_key)
                    backward_key_set[lower_level_block_key] = backward_keys
                    forward_key_set[lower_level_block_key] = forward_keys
                    is_one_to_one_set[lower_level_block_key] = is_one_to_one
                # for the highest level, we should really use the primary key to give a natural ordering
                # use forward keys for the moment
                this_level_chaintable = streamer.chain(prior, forward_keys_from_higher_level,
                                                       backward_key_set,
                                                       backward_keys_for_mapping,
                                                       block_at_this_level.fields(),
                                                       block_at_this_level.name(),
                                                       block_at_this_level.where_clause(), master_timestamp,
                                                       master_as_of, master_offset, master_limit)

                for lower_level_block_key, lower_level_block_value in lower_levels_blocks.items():
                    forward_keys_for_lower_level = forward_key_set.get(lower_level_block_key)
                    backward_keys_for_lower_level = backward_key_set.get(lower_level_block_key)
                    if forward_keys_for_lower_level is None:
                        err_msg = f'No relationship defined for {lower_level_block_key}'
                        raise RelationshipException(err_msg)
                    lower_level_table = self.construct_chain_recursive(lower_level_block_value,
                                                                       this_level_chaintable,
                                                                       forward_keys_for_lower_level,
                                                                       backward_keys_for_lower_level, master_timestamp,
                                                                       master_as_of, None, None)
                    row_number_to_upper_level = this_level_chaintable.row_number_to_upper_level()
                    for forward_key, value in lower_level_table.forward_results().items():
                        # forward key from below is this level's row number
                        collected_forward_row_number_for_this_table = row_number_to_upper_level[forward_key]
                        parent_object_keys = this_level_chaintable.forward_results().get(collected_forward_row_number_for_this_table)
                        parent_obj = parent_object_keys[forward_key]
                        for val in value.values():
                            if parent_obj.get(lower_level_block_key) is None:
                                if is_one_to_one_set[lower_level_block_key]:
                                    parent_obj[lower_level_block_key] = val
                                else:
                                    # an association table might return us a list of values per row
                                    # we shall accept the list "as-is" rather than making a list of it
                                    #TODO - re-examine this when the returned list is reflecting points in time
                                    if isinstance(val, list):
                                        parent_obj[lower_level_block_key] = val
                                    else:
                                        parent_obj[lower_level_block_key] = [val]
                            else:
                                parent_obj[lower_level_block_key].append(val)
                        #if parent_obj.get(lower_level_block_key) is None:
                        #    if is_one_to_one_set[lower_level_block_key] and len(value) == 1:
                        #        parent_obj[lower_level_block_key] = value[0]
                        #    else:
                        #        parent_obj[lower_level_block_key] = value
                        #else:
                        #    parent_obj[lower_level_block_key].append(value)

                        #value = reduce(lambda a,b: a+b, list(value.values()))
                        #if parent_obj.get(lower_level_block_key) is None:
                        #    if is_one_to_one_set[lower_level_block_key] and len(value) == 1:
                        #        parent_obj[lower_level_block_key] = value[0]
                        #    else:
                        #        parent_obj[lower_level_block_key] = value
                        #else:
                        #    parent_obj[lower_level_block_key].append(value)

                    print("Checking for filtering at lower level")
                    # if the lower level table is filtered, knock out all the parent entries which haven't got a child
                    # from this lower_level_table
                    #if lower_level_block_value[ExecutionChain.DATA_BLOCK_AT_THIS_LEVEL].is_filtered():
                    this_level_chaintable.filter_results(lower_level_block_key)
                return this_level_chaintable
        except ColumnByNameException as cbn:
            print(str(cbn))
            raise cbn  # re-raise it to a higher level
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
            raise e  # re-raise it to a higher level
