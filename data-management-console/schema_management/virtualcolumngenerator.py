# Turns the 1:1 and 1:n Foreign Keys into virtual columns for easier DSL syntax.
# Uses various templated sql files within the sql/ directory and substitutes the key variables into them
from schema_management.abbreviatename import AbbreviateName
from sql.sql_runner import SqlRunner
from schema_management.tabledefinitions import TableDefinition, VirtualColumn


class AbbreviationException(Exception):
    pass


class IllegalFKConfigurationException(Exception):
    pass


class VirtualColumnGenerator:

    @staticmethod
    def create_1to1_functions_and_triggers(cursor, fact_table_name, reference_table_name, value_column_name,
                                           target_columns, arg_types, known_as, other_field):
        abbreviated_name = AbbreviateName.abbreviate_name([reference_table_name])
        abbreviated_get_function = AbbreviateName.abbreviate_name(
            ["get", fact_table_name, reference_table_name, known_as])
        replacement_dict = {"%REFERENCE_TABLE_NAME%": abbreviated_name,
                            "%GET_FUNCTION%": abbreviated_get_function,
                            "%VALUE_COLUMN%": value_column_name,
                            "%TARGET_COLUMN_NAME%": target_columns[0]
                            }
        for i in range(0, len(target_columns)):
            replacement_dict[f'%TARGET_COLUMN_NAME{i}%'] = target_columns[i]
        for i in range(0, len(arg_types)):
            replacement_dict[f'%ARG_TYPE{i}%'] = arg_types[i]
        #        SqlRunner.execute_file_with_substitution(cursor, '../sql/template_staging_1to1.sql', replacement_dict)
        SqlRunner.execute_file_with_substitution(cursor, f'../sql/get_function1to1.sql',
                                                 replacement_dict)

    @staticmethod
    def create_1ton_functions_and_triggers(cursor, reference_table_name, value_column_name,
                                           source_columns, arg_types, association_table_alias, residual_field,
                                           table_with_residual):
        abbreviated_get_function = AbbreviateName.abbreviate_name(
            ["get", association_table_alias])
        replacement_dict = {"%REFERENCE_TABLE_NAME%": reference_table_name,
                            "%GET_FUNCTION%": abbreviated_get_function,
                            "%VALUE_COLUMN%": value_column_name,
                            "%ASSOC_TABLE_NAME%": association_table_alias
                            }
        for i in range(0, len(source_columns)):
            replacement_dict[f'%SOURCE_COLUMN_NAME{i}%'] = source_columns[i]
        for i in range(0, len(arg_types)):
            replacement_dict[f'%ARG_TYPE{i}%'] = arg_types[i]
        #       SqlRunner.execute_file_with_substitution(cursor, '../sql/template_staging_1ton.sql', replacement_dict)
        if residual_field:
            replacement_dict["%RESIDUAL_FIELD%"] = residual_field
            replacement_dict["%RESIDUAL_TABLE%"] = table_with_residual
            SqlRunner.execute_file_with_substitution(cursor, f'../sql/get_function{len(source_columns)}_with_other.sql',
                                                     replacement_dict)
        else:
            SqlRunner.execute_file_with_substitution(cursor, f'../sql/get_function{len(source_columns)}.sql',
                                                     replacement_dict)

        # now make sure that the underlying reference data table has an appropriate trigger on it too

    #        abbreviated_name = AbbreviateName.abbreviate_name([reference_table_name])
    #        replacement_dict = {"%REFERENCE_TABLE_NAME%": abbreviated_name}
    #        SqlRunner.execute_file_with_substitution(cursor, f'../sql/template_staging.sql', replacement_dict)

    @staticmethod
    def create_virtual_column_functions(cursor, schema_tables: list[TableDefinition]):
        for table in schema_tables:
            for fk in table.foreign_keys():
                if len(fk.target_columns()) != 1:
                    #                    raise IllegalFKConfigurationException(
                    #                        "Can only have one target column in FK for auto-generated virtual column")
                    # TODO - handle these implied foreign keys better
                    print("Skipping where more than 1 target column")
                    continue
                if fk.known_as() == "_internal_":
                    print("Skipping as this is a logical connection for reporting purposes only")
                    continue
                arg_types = [table.column_by_name(col_name).data_type() for col_name in fk.source_columns()]
                print(f"arg types is {arg_types}")
                if fk.is_one_to_one():  # a 1-1 key
                    VirtualColumnGenerator.create_1to1_functions_and_triggers(cursor, table.name(),
                                                                              fk.target_table(),
                                                                              fk.lookup_columns()[0],
                                                                              fk.target_columns(),
                                                                              arg_types,
                                                                              fk.known_as(),
                                                                              fk.other_field())
                else:
                    VirtualColumnGenerator.create_1ton_functions_and_triggers(cursor,
                                                                              fk.target_table(),
                                                                              fk.lookup_columns()[0],
                                                                              fk.source_columns(),
                                                                              arg_types,
                                                                              fk.association_table_alias(),
                                                                              fk.other_field(),
                                                                              table.name())

    @staticmethod
    def create_virtual_columns(schema_tables: list[TableDefinition]):
        for table in schema_tables:
            for fk in table.foreign_keys():
                vc_name = fk.known_as()
                associated_names = ",".join(fk.target_columns())
                source_table_name = fk.table_name()
                target_table_name = fk.target_table()
                known_as = fk.known_as()
                if fk.known_as() == "_internal_":
                    continue
                if fk.is_one_to_one():
                    func_name = AbbreviateName.abbreviate_name(
                        ["get", source_table_name, target_table_name, known_as])
                    print(f'Handling 1-1 FK to {target_table_name}')
                else:
                    association_table_alias = fk.association_table_alias()
                    func_name = AbbreviateName.abbreviate_name(
                        ["get", association_table_alias])
                    print(f'Handling 1-n FK to {target_table_name}')

                # add in the timestamp and the as_of - these will be replaced in the routine translate_virtual_fields
                # TODO - make these constants
                full_function_args = [f'{source_table_name}.{src}' for src in fk.source_columns()]
                full_function_args.append('update_time')
                full_function_args.append('as_of')
                print(f'full function args are {full_function_args}')
                full_function_call = f'{func_name}({",".join(full_function_args)})'
                print(full_function_call)
                try:
                    vc = VirtualColumn(table.name(), vc_name, associated_names, full_function_call, "varchar(10000)")
                    table.add_column(vc)
                except Exception as e:
                    print(str(e))
                    raise e
