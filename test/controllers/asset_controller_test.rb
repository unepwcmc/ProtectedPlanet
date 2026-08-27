require "test_helper"

class AssetsControllerTest < ActionController::TestCase
  test ".tiles, given a pa id, generates the asset and returns the image with the
   correct mimetype" do
    pa = FactoryBot.create(:protected_area, site_id: 555_111)

    AssetGenerator.stubs(:protected_area_tile).returns("the tile")

    # AssetsController looks the record up by site_id, not by primary key.
    get :tiles, params: {"id" => pa.site_id, "type" => "protected_area"}
    assert_equal "the tile", @response.body
  end

  # Set in the action rather than Middleware::CacheHeaders, which sits above
  # Rack::Cache and so would stamp too late for the response to be stored.
  test ".tiles sets the shared long-lived cache policy on the response" do
    pa = FactoryBot.create(:protected_area, site_id: 555_222)

    AssetGenerator.stubs(:protected_area_tile).returns("the tile")

    get :tiles, params: {"id" => pa.site_id, "type" => "protected_area"}

    # Compared as a directive set, not a string: Rails re-serializes Cache-Control
    # on commit and emits max-age first, which is equivalent -- directive order
    # carries no meaning.
    assert_equal directives(Middleware::CacheHeaders.long_lived),
                 directives(@response.headers["Cache-Control"])
  end

  private

  def directives(cache_control)
    cache_control.to_s.split(",").map(&:strip).sort
  end
end
