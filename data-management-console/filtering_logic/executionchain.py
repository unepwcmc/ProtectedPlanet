import traceback

from filtering_logic.blockregistry import BlockRegistry
from filtering_logic.chaintable import ChainTable
from filtering_logic.datablock import DataBlock


class ExecutionChain:
    DATA_BLOCK_AT_THIS_LEVEL = "."

    def __init__(self):
        self._chain = {}
        self._blocks_referenced = {}
        BlockRegistry.reset()

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

    def get_block_for_name(self, table_name):
        if self._blocks_referenced.get(table_name):
            return self._blocks_referenced[table_name]
        data_block = BlockRegistry.get_block_for_name(table_name)
        if isinstance(data_block, str):
            data_block = self.get_block_for_name(data_block)
        self._blocks_referenced[table_name] = data_block
        return data_block

    def get_chain_item(self, dict_obj, head_item, tail_items):
        val = dict_obj.get(head_item)
        if val is None:
            return None
        if tail_items:
            return self.get_chain_item(dict_obj[head_item], tail_items[0], tail_items[1:])
        return val

    def construct_chain(self, master_timestamp, master_as_of, master_offset, master_limit):
        assert (len(self._chain) < 2)
        table_name = list(self._chain.keys())[0]
        val = list(self._chain.values())[0]
        top_level_chaintable = self.construct_chain_recursive(table_name, val, None, master_timestamp, master_as_of, master_offset, master_limit)
        return {"data": list(top_level_chaintable.forward_results().values()), "max_rows":top_level_chaintable.max_rows_retrievable()}

    def construct_chain_recursive(self, table_name: str, chain: dict, prior, master_timestamp, master_as_of, master_offset, master_limit):
        # walk the chain of datablocks from the root, joining them up as you go
        # at each level get the root item, evaluate it and then chain everything else at this level from it
        block_at_this_level = chain[ExecutionChain.DATA_BLOCK_AT_THIS_LEVEL]
        streamer = block_at_this_level.streamer()
        try:
            this_level_chaintable: ChainTable = streamer.chain(prior, block_at_this_level.forward_keys(),
                                                               block_at_this_level.backward_keys(),
                                                               block_at_this_level.fields(), block_at_this_level.name(),
                                                               block_at_this_level.where_clause(), master_timestamp,
                                                               master_as_of, master_offset, master_limit)
            lower_levels_blocks = {key: value for key, value in chain.items() if
                                   key != ExecutionChain.DATA_BLOCK_AT_THIS_LEVEL}
            for lower_level_block_key, lower_level_block_value in lower_levels_blocks.items():
                lower_level_table = self.construct_chain_recursive(lower_level_block_key, lower_level_block_value,
                                                                   this_level_chaintable, master_timestamp,
                                                                   master_as_of, 0, 1000000)
                back_res = this_level_chaintable.backward_results()
                for forward_key, value in lower_level_table.forward_results().items():
                    parent_object_keys = back_res.get(forward_key)
                    for parent_obj_key in parent_object_keys:
                        parent_obj = this_level_chaintable.forward_results().get(parent_obj_key)
                        if parent_obj.get(lower_level_block_key) is None:
                            parent_obj[lower_level_block_key] = [value]
                        else:
                            parent_obj[lower_level_block_key].append(value)
                # if the lower level table is filtered, knock out all the parent entries which haven't got a child
                # from this lower_level_table
                # if lower_level_block_value[ExecutionChain.DATA_BLOCK_AT_THIS_LEVEL].is_filtered():
                # this_level_chaintable.filter_results(lower_level_block_key)

            return this_level_chaintable
        except Exception as e:
            print(str(e))
            traceback.print_exc(limit=None, file=None, chain=True)
