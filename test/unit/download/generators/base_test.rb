require 'test_helper'

class DownloadGeneratorsBaseTest < ActiveSupport::TestCase
  test '#generate, given a path and an empty selection, returns immediately' do
    Download::Generators::Base.any_instance.expects(:export).never
    Download::Generators::Base.any_instance.expects(:zip).never

    Download::Generators::Base.generate('./none.zip', { site_ids: [] })
  end
end
