require 'test_helper'

class AddItemToProjectsTest < ActionDispatch::IntegrationTest

  def setup
    @user = FactoryGirl.create(:user)

    @region = FactoryGirl.create(:region)
    @country = FactoryGirl.create(:country, region: @region)

    @pa = FactoryGirl.create(:protected_area,
      name: "Test PA", countries: [@country])
    @project = FactoryGirl.create(:project,
      name: "My New Project", user: @user)

    sign_in @user

    search_mock = mock().tap { |m| m.stubs(:results).returns([]) }
    Search.stubs(:search).returns(search_mock)
  end

  test "add region to existing project" do
    skip
    FactoryGirl.create(:regional_statistic, region: @region)

    visit regional_stats_path(@region.iso)
    add_item_to_project
    assert_includes Project.last.items, @region
  end

  test "add country to existing project" do
    FactoryGirl.create(:country_statistic, country: @country)

    visit country_stats_path(@country.iso)
    add_item_to_project
    assert_includes Project.last.items, @country
  end

  test "add pa to existing project" do
    visit protected_area_path(@pa.wdpa_id)
    add_item_to_project
    assert_includes Project.last.items, @pa
  end

  def add_item_to_project
    within('#add_to_projects_form') do
      select @project.name, :from => 'project_id'
      click_button 'Add to Projects'
    end
  end
end
