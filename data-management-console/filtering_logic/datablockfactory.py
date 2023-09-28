# The DataBlockFactory is called during startup of the Data Management Service to pre-create all the blocks
# referenced within the metadata i.e. the universe of blocks on which the DSL may operate.
# Accordingly, it will create both simple (for single table) and compound (for association table) blocks.

from filtering_logic.blockregistry import BlockRegistry
from filtering_logic.datablock import DataBlock, AssociationDataBlock
from filtering_logic.selectionengineexceptions import MalformedCompoundBlockException


class DataBlockFactory:

    @classmethod
    def create_simple_block(cls, table_name) -> DataBlock:
        db = BlockRegistry.get_block_for_name(table_name)
        if db is None:
            db = BlockRegistry.add_block(table_name, DataBlock(table_name))
        return db

    @classmethod
    def create_compound_block(cls, fully_qualified_name: list[str], block_name_list: list[str]) -> DataBlock:
        if len(fully_qualified_name) != 2 or len(block_name_list) != 2:
            err_msg = f"Compound Block doesn't contain exactly 2 table names:  {','.join(fully_qualified_name)}"
            raise MalformedCompoundBlockException(err_msg)
        cdb = BlockRegistry.get_compound_block_for_name(fully_qualified_name)
        if cdb is None:
            if "iso3" in block_name_list:
                pass
            first_block = cls.create_simple_block(block_name_list[0])
            second_block = cls.create_simple_block(block_name_list[1])
            cdb = BlockRegistry.add_compound_block(fully_qualified_name,
                                                   AssociationDataBlock(fully_qualified_name, first_block,
                                                                        second_block))
        return cdb
