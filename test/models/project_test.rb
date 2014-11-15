require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test '.items returns all items collected from has_many relations' do
    project = FactoryGirl.create(:project)
    pa = FactoryGirl.create(:protected_area, projects: [project])
    country = FactoryGirl.create(:country, projects: [project])
    region = FactoryGirl.create(:region, projects: [project])

    assert_same_elements [pa, country, region], project.items
  end

  test '.download_info returns an hash of information about the download link' do
    project = FactoryGirl.create(:project)
    expected_json = '{"link": "this_is_the_link"}'

    $redis.expects(:get).returns(expected_json)

    assert_equal 'this_is_the_link', project.download_info['link']
  end
end
