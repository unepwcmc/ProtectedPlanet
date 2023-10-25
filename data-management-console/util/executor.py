from abc import ABC, abstractmethod


class Executor(ABC):

    @abstractmethod
    def begin_transaction(self):
        pass

    @abstractmethod
    def end_transaction(self):
        pass

    @abstractmethod
    def open_read_cursor(self):
        pass

    @abstractmethod
    def store_transformed_and_associated_rows(self, table_store, distinct_rows_only):
        pass

    @abstractmethod
    def widen_field(self, target_table:str, target_attribute:str, required_width:int):
        pass


class ExecutorNeededException(Exception):
    pass
