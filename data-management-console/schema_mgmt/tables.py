import copy
from mgmt_logging.logger import Logger

class TableColumn:
	def __init__(self, table_name, name, data_type):
		self.table_name = table_name.strip()
		self.name = name.strip()
		self.data_type = data_type

	def __str__(self):
		return f"{self.name} : {self.data_type}"

	def convert(self, converter):
		return converter.code_column(self.name, self.data_type)

	def metadata(self):
		return (self.table_name, self.name, self.data_type, "")


class PrimaryKey:
	def __init__(self, table_name, column_names):
		self.column_names = column_names
		self.name = "PK_" + table_name
		self.table_name = table_name

	def convert(self, converter):
		return converter.code_primary_key(self.column_names)

	def metadata(self):
		return (self.table_name, self.name, "PRIMARY KEY", ",".join(self.column_names))


class ForeignKey:
	key_count = 0

	def __init__(self, table_name, source_columns, target_table, target_columns):
		self.table_name = table_name
		self.source_columns = [source_column.strip() for source_column in source_columns]
		self.target_table = target_table
		self.target_columns = [target_column.strip() for target_column in target_columns]
		self.name = "FK_" + table_name + str(self.next_key())

	@classmethod
	def next_key(cls):
		val = cls.key_count
		cls.key_count += 1
		return val

	def convert(self, converter):
		return converter.codeForeignKey(self.source_columns, self.target_table, self.target_columns)

	def metadata(self):
		return (self.table_name, self.name, "FOREIGN KEY", ",".join(self.target_columns))


class TableRow:
	def __init__(self, table_def):
		self.table_def = table_def		# this is a TableDefinition
		self.fields = {}

	def get_value(self, column_name):
		if column_name in self.fields:
			return self.fields[column_name]
		return None

	def set_value(self, column_name, val):
		self.fields[column_name] = val

	def __eq__(self, other_row):
		return (self.table_def.name == other_row.table_def.name) and (self.fields == other_row.fields)


class TableDefinition:
	def __init__(self, name, elements):
		self.name = name
		self.elements = elements

	def __str__(self):
		elements = [str(el) for el in self.elements]
		return(f"{self.name} has {len(self.elements)} elements -> {','.join(elements)}")

	def convert(self, converter):
		cols = [el.convert(converter) for el in self.columns()]
		if self.primary_key() is not None:
			cols.append(self.primary_key().convert(converter))
		return cols

	def add_historical_columns(self, historical_table_def):
		Logger.get_logger().info(f'Adding historical columns from {historical_table_def.name} to {self.name}')
		historical_columns_added = copy.deepcopy(historical_table_def.columns())
		for el in historical_columns_added:
			el.table_name = self.name
		elements = self.elements + historical_columns_added
		historical_primary_key = historical_table_def.primary_key()
		if historical_primary_key is not None:
			Logger.get_logger().info(f'Historical primary key is {historical_primary_key.column_names}')
			self_primary_key = self.primary_key()
			self_primary_key.column_names.append(historical_primary_key.column_names)
			Logger.get_logger().info(f'There are now {len(self_primary_key.column_names)} elements in the PK')
		return TableDefinition(self.name, elements)

	def add_ingestion_columns(self, ingestion_table_def):
		ingestion_columns_added = copy.deepcopy(ingestion_table_def.columns())
		for el in ingestion_columns_added:
			el.table_name = self.name
		elements = self.elements + ingestion_columns_added
		return TableDefinition(self.name, elements)
			
	def primary_key(self):
		primary_key = filter(lambda x: isinstance(x, PrimaryKey), self.elements)
		vals = list(primary_key)
		if len(vals) == 0:
			return None
		return vals[0]

	def columns(self):
		return list(filter(lambda x: isinstance(x, TableColumn), self.elements))
