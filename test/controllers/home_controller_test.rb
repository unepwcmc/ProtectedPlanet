require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get index" do
    seed_cms_home
    # The home page renders GlobalStatistic coverage percentages (HomePresenter
    # calls .round on them); the singleton row exists but its columns are nil
    # until seeded. In production these are always populated.
    GlobalStatistic.instance.update!(
      total_land_pa_coverage_percentage: 12.0,
      total_ocean_pa_coverage_percentage: 8.0,
      total_land_oecms_pas_coverage_percentage: 1.0,
      total_ocean_oecms_pas_coverage_percentage: 2.0
    )

    get :index
    assert_response :success
  end
end
