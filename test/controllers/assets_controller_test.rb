require 'test_helper'

class AssetsControllerTest < ActionController::TestCase
  test '.tiles, given a pa id, generates the asset and returns the image with the
   correct mimetype' do
    pa = FactoryGirl.create(:protected_area)
    params = {'size' => {'x' => 256, 'y' => 128}}

    AssetGenerator.stubs(:protected_area_tile).returns('the tile')

    get :tiles, 'id' => pa.id, 'version' => 1,'size' => {'x' => 256, 'y' => 128}
    assert_equal 'the tile', @response.body
  end
end
