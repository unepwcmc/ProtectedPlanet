require 'dbf'

class DbfGetter

  def columns filename: filename
    dbf_table = DBF::Table.new(filename)
    columns_list = []
    dbf_table.columns.each do |column|
      columns_list << column.name
    end
    return columns_list
  end

end