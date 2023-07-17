from abc import ABC, abstractmethod

# we need to define a datasource
# each datasource then has multiple datablocks; each datablock defines its FK for join and its PK
# each step must link an FK to the prior table's PK (or similar) if there is a single step
# a 1:n relationship must work differently - the middle table is "invisible" and is automatically joined
# to the end_table.
# so iso3 is really iso3 -> wdpa_iso3_assoc

class DataSource(ABC):

    def __init__(self, name):
        self.name = name

    @abstractmethod
    def register_block_names(self):
        pass
