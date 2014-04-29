require 'test_helper'

class TestImport < ActiveSupport::TestCase
  def test_import_downloads_the_WDPA_database_and_imports_it
    FactoryGirl.create(:protected_area)

    assert_difference 'ProtectedArea.count', 1 do
      Import.(url: 'http://s3.com/wdpa.zip')
    end
  end
end
