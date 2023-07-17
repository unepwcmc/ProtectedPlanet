from filtering_logic.datablock import DataBlock


class BlockRegistry:
    _registry = {}

    @classmethod
    def add_block(cls, block_name, block_instance):
        cls._registry[block_name] = block_instance

    @classmethod
    def get_block_for_name(cls, block_name):
        return cls._registry[block_name]

    @classmethod
    def reset(cls):
        for block in cls._registry.values():
            if isinstance(block, DataBlock):
                block.reset()