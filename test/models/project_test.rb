require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test '.items returns all items collected from has_many relations' do
    project = FactoryGirl.create(:project)
    pa = FactoryGirl.create(:protected_area, projects: [project])
    country = FactoryGirl.create(:country, projects: [project])
    region = FactoryGirl.create(:region, projects: [project])

    assert_same_elements [pa, country, region], project.items
  end

  test '.download_link, given a type, returns a link to the project download' do
    project = FactoryGirl.create(:project)
    expected_link = "http://link.to/prject_download_csv.zip"

    Download.expects(:link_to).
      with("project_#{project.id}_all", :csv).
      returns(expected_link)

    assert_equal expected_link, project.download_link(:csv)
  end
end
