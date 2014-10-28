require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  test 'gets index' do
    get :index
    assert_response :success
  end

  test '.create creates a project containing the given item' do
    pa = FactoryGirl.create(:protected_area)

    assert_difference('Project.count', 1) do
      post :create, item_id: pa.id, item_type: 'protected_area'
    end

    assert_redirected_to projects_path
    assert_includes Project.first.items, pa
  end

  test '.update, given a project id, updates the project with the given params' do
    project = FactoryGirl.create(:project, name: 'test_project')

    put(:update, id: project.id, project: {name: 'new_test_project'})

    assert_response :success
    assert_equal 'new_test_project', project.reload.name
  end
end
