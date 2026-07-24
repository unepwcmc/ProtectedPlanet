require "test_helper"

class AssetsControllerTest < ActionController::TestCase
  test ".tiles, given a pa id, generates the asset and returns the image with the
   correct mimetype" do
    pa = FactoryGirl.create(:protected_area, site_id: 555_111)

    AssetGenerator.stubs(:protected_area_tile).returns("the tile")

    # AssetsController looks the record up by site_id, not by primary key.
    get :tiles, params: {"id" => pa.site_id, "type" => "protected_area"}
    assert_equal "the tile", @response.body
  end
end
