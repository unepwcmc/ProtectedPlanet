require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test '.items returns all items collected from has_many relations' do
    project = FactoryGirl.create(:project)
    pa = FactoryGirl.create(:protected_area, projects: [project])
    country = FactoryGirl.create(:country, projects: [project])
    region = FactoryGirl.create(:region, projects: [project])

    assert_same_elements [pa, country, region], project.items
  end
end
