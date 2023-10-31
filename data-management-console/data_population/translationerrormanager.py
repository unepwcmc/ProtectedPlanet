from typing import Any

from util.logger import Logger


class TranslationException(Exception):

    def __init__(self, key_errors: set, foreign_key_errors: set, unknown_attribute_errors: set,
                 field_length_errors: [], coerced_values: set):
        super().__init__("Errors found")
        self._key_errors = key_errors
        self._foreign_key_errors = foreign_key_errors
        self._unknown_attribute_errors = unknown_attribute_errors
        self._field_length_errors = field_length_errors
        self._coerced_values = coerced_values

    def coerced_values(self):
        return self._coerced_values

    def field_length_errors(self):
        return self._field_length_errors

    def unknown_attribute_errors(self):
        return self._unknown_attribute_errors

    def log_errors(self):
        Logger.get_logger().info("Unknown columns for mapping")
        for key_err in self._key_errors:
            Logger.get_logger().info(str(key_err))
        Logger.get_logger().info("Nonexistent Foreign Key Errors")
        for for_key_err in self._foreign_key_errors:
            Logger.get_logger().info(str(for_key_err))
        Logger.get_logger().info("Unknown Attribute Errors")
        for unk_att_err in self._unknown_attribute_errors:
            Logger.get_logger().info(str(unk_att_err))


class TranslationErrorManager:

    def __init__(self):
        self._key_errors = set()
        self._foreign_key_errors = set()
        self._unknown_attribute_errors = set()
        self._incorrect_cardinalities = set()
        self._field_length_errors = {}
        self._coerced_values = set()

    def add_field_too_long_error(self, table_name: str, attribute_name: str, current_length: int, length_required: int):
        existing_entry = self._field_length_errors.get((table_name, attribute_name))
        if existing_entry:
            self._field_length_errors[(table_name, attribute_name)] = (current_length, max(existing_entry[1], length_required))
        else:
            self._field_length_errors[(table_name, attribute_name)] = (current_length, length_required)

    def add_unknown_source_columns(self, source_columns: list[str], target_table: str):
        self._key_errors.add((",".join(source_columns), target_table))

    def add_nonexistent_foreign_key_error(self, source_table, target_table, lookup_column):
        self._foreign_key_errors.add((source_table, target_table, lookup_column))

    def add_unknown_attribute(self, fk_table: str, lookup_column: str, value: Any):
        self._unknown_attribute_errors.add((fk_table, lookup_column, value))

    def add_translation_not_1ton(self, target_attribute: str, target_table: str):
        self._incorrect_cardinalities.add((target_attribute, target_table))

    def add_value_needs_to_be_coerced(self, table_name: str, target_name: str, current_value: Any, proposed_value: Any):
        self._coerced_values.add((table_name, target_name, str(current_value), str(proposed_value)))

    def coerced_values(self):
        return self._coerced_values

    def field_length_errors(self):
        return [(k[0], k[1], v[0], v[1]) for k, v in self._field_length_errors.items()]

    def has_errors(self):
        return self._coerced_values or self._field_length_errors or self._foreign_key_errors or self._unknown_attribute_errors

    def has_errors_which_must_be_fixed(self):
        return self._field_length_errors or self._foreign_key_errors or self._unknown_attribute_errors

    def raise_any_errors(self):
        if self._key_errors or self._foreign_key_errors or self._unknown_attribute_errors or self._field_length_errors or self._coerced_values:
            raise TranslationException(self._key_errors, self._foreign_key_errors, self._unknown_attribute_errors,
                                       self.field_length_errors(), self.coerced_values())

    def unknown_attributes(self):
        return self._unknown_attribute_errors
