require 'test_helper'
require 'dbf'

class TestDbfGetter < ActiveSupport::TestCase
  test '.columns gets the names of the columns in a dbf file and brigns them as an array' do
    filename = 'chewy.dbf'

    column_mock = mock()
    table_mock = mock()
    column_mock.expects(:name).returns('chewie')
    table_mock.expects(:columns).returns([column_mock])
    DBF::Table.expects(:new).returns(table_mock)

    dbf_column_names = DbfGetter.new
    columns = dbf_column_names.columns filename: filename 
    assert_equal ['chewie'], columns 

  end
end
