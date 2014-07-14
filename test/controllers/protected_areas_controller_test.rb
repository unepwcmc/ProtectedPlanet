require 'test_helper'

class ProtectedAreasControllerTest < ActionController::TestCase
  def setup
    @region  = FactoryGirl.create(:region, name: 'Killbeurope')
    @country = FactoryGirl.create(:country, name: 'Killbearland', region: @region)
    @protected_area = FactoryGirl.create(:protected_area, name: 'Killbear', countries: [@country])
  end

  test '#show returns a 200 HTTP code' do
    get :show, id: @protected_area.slug
    assert_response :success
  end

  test '#show is successful even if no jurisdiction is present' do
    designation = FactoryGirl.create(:designation)
    region = FactoryGirl.create(:region)
    country = FactoryGirl.create(:country, region: region)

    protected_area = FactoryGirl.create(
      :protected_area, designation: designation, countries: [country]
    )

    get :show, id: protected_area.wdpa_id
  end

  test '#show does not select the geometry when loading the Protected
   Area' do
    geometry_wkt = "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))"
    @protected_area.update_attributes(the_geom: geometry_wkt)

    get :show, id: @protected_area.slug

    selected_protected_area = assigns :protected_area

    assert_not_nil selected_protected_area
    refute selected_protected_area.has_attribute?(:the_geom)
  end
end
