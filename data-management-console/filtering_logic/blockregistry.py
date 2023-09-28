# The BlockRegistry maintains a mapping of names to DataBlock|AssociationBlock - this way,
# the same block is used whenever the same simple or compound name is encountered within a query.
# Compound names are used when an association is being represented and map to AssociationBlocks; the goal
# is to hide the association table from the user in order to make the syntax clearer to understand e.g.
# iso3.wdpa navigates from iso3 to wdpa_iso3_assoc to wdpa.  Simple names are individual tables e.g. wdpa.
# When asked to find the block corresponding to a name, the BlockRegistry first checks for compound names
# and then simple names.

from filtering_logic.datablock import DataBlock, AssociationDataBlock
from filtering_logic.queryexceptions import UnknownBlockException


class BlockRegistry:
    _registry = {}
    _block_registry = {}

    @classmethod
    def add_block(cls, block_name, block_instance) -> DataBlock:
        cls._registry[block_name] = block_instance
        return block_instance

    @classmethod
    def add_compound_block(cls, fully_qualified_block_name: list[str],
                           block_instance: AssociationDataBlock) -> DataBlock:
        cls._block_registry[".".join(fully_qualified_block_name)] = block_instance
        return block_instance

    @classmethod
    def get_block_for_name(cls, block_name, strict: bool = False) -> DataBlock:
        val = cls._registry.get(block_name)
        if val is None and strict:
            err_msg = f'There is no block registered by the name {block_name}'
            raise UnknownBlockException(err_msg)
        return val

    @classmethod
    def reset(cls):
        cls._block_registry.clear()

    @classmethod
    def clear_where_conditions(cls):
        for val in cls._registry.values():
            val.reset()
        for val in cls._block_registry.values():
            val.reset()

    @classmethod
    def get_compound_block_for_name(cls, fully_qualified_table_name: list[str],
                                    strict: bool = False) -> AssociationDataBlock:
        block_name = ".".join(fully_qualified_table_name)
        val = cls._block_registry.get(block_name)
        if val is None and strict:
            err_msg = f'There is no block registered by the name {block_name}'
            raise UnknownBlockException(err_msg)
        return val
