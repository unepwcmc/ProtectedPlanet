require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  test '.create creates a project containing the given item' do
    pa = FactoryGirl.create(:protected_area)

    assert_difference('Project.count') do
      post :create, first_item_id: pa.id, first_item_type: 'protected_area'
    end

    assert_redirected_to projects_path
    assert_includes Project.first.items, pa
  end
end
