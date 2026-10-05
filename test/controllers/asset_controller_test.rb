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
    @controller.stubs(:perform_caching).returns(true)

    get :tiles, params: {"id" => pa.site_id, "type" => "protected_area"}

    # Compared as a directive set, not a string: Rails re-serializes Cache-Control
    # on commit and emits max-age first, which is equivalent -- directive order
    # carries no meaning.
    assert_equal directives(Middleware::CacheHeaders.long_lived),
                 directives(@response.headers["Cache-Control"])
  end

  # Every type in TYPES must reach a generator that actually exists. This is the
  # one thing grep cannot check: country_tile/region_tile were deleted as dead
  # code while AssetsController still reached them through a built method name
  # ("#{area_type}_tile"), so they had no literal call site anywhere and both
  # endpoints 500d. Deleting either one now fails here.
  test ".tiles returns a tile for every type in TYPES" do
    AppSecrets.stubs(:mapbox).returns({"base_url" => "http://mapbox.com/", "access_token" => "123"})
    # Stubbed at the network boundary, NOT on the *_tile methods themselves:
    # mocha happily stubs a method that does not exist, so stubbing those would
    # define the very thing this test exists to prove is still there.
    AssetGenerator.stubs(:request_tile).returns("the tile")
    ProtectedArea.any_instance.stubs(:geojson).returns("{}")
    Country.any_instance.stubs(:geojson).returns("{}")
    Region.any_instance.stubs(:geojson).returns("{}")

    ids = {
      "protected_area" => FactoryBot.create(:protected_area, site_id: 555_333).site_id,
      "country" => FactoryBot.create(:country, iso: "TL", iso_3: "TLX").iso,
      "region" => FactoryBot.create(:region, iso: "TLR").iso
    }
    assert_equal AssetsController::TYPES.sort, ids.keys.sort,
                 "a tile type was added to TYPES without coverage here"

    ids.each do |type, id|
      get :tiles, params: {"id" => id, "type" => type}
      assert_equal "the tile", @response.body, "no tile generated for type=#{type}"
    end
  end

  private

  def directives(cache_control)
    cache_control.to_s.split(",").map(&:strip).sort
  end
end
