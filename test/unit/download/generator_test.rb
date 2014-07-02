require 'test_helper'

class DownloadGeneratorTest < ActiveSupport::TestCase
  test '#generate, given a path and an empty array of wdpa_ids,
   returns immediately' do
    Download::Generator.any_instance.expects(:export).never
    Download::Generator.any_instance.expects(:zip).never

    Download::Generator.generate('./none.zip', [])
  end
end
