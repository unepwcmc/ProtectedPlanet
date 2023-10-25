from data_population.translationerrormanager import TranslationErrorManager


class TranslationReferenceDataObject:

    def __init__(self, source_table_name: str, creation_time: str, data_group: str,
                 error_manager: TranslationErrorManager):
        self._source_table_name = source_table_name
        self._creation_time = creation_time
        self._data_group = data_group
        self._error_manager = error_manager

    def creation_time(self) -> str:
        return self._creation_time

    def data_group(self) -> str:
        return self._data_group

    def error_manager(self) -> TranslationErrorManager:
        return self._error_manager

    def source_table_name(self) -> str:
        return self._source_table_name
