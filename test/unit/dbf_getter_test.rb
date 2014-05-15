require 'test_helper'
require 'dbf'

class TestDbfGetter < ActiveSupport::TestCase
  test '.columns gets the names of the columns in a dbf file and brigns them as an array' do
    filename = 'chewy.dbf'
    column_name_mock = mock()

    table_mock = mock()
    columns_mock.expects(:each).returns(column_name_mock)
    table_mock = mock()
    table_mock.expects(:columns).returns(columns_mock)
    DBF::Table.expects(:new).returns(table_mock)

    dbf_column_names = DbfGetter.new
    dbf_column_names.columns filename: filename 

  end
end
