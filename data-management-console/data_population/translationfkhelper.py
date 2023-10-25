from util.metadatareader import MetadataReader
from schema_management.tabledefinitions import ForeignKey
from data_population.translationexceptions import TranslationReferencingUnknownFKException


class TranslationFKHelper:

    @staticmethod
    def fk_for_attribute(table_name, attribute_name) -> ForeignKey:
        table_info = MetadataReader.tables().get(table_name)
        if table_info is None:
            err_msg = f'Unknown table {table_name} being referenced in translation file'
            raise TranslationReferencingUnknownFKException(err_msg)
        fk: ForeignKey = table_info.fk_for_attribute(attribute_name)
        return fk
