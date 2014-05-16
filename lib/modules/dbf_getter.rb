require 'dbf'

class DbfGetter

  def columns filename: filename
    dbf_table = DBF::Table.new(filename)
    dbf_table.columns.map(&:name)
  end

end