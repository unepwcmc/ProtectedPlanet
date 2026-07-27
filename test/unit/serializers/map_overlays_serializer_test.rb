require 'test_helper'

# Snapshot of the map-overlay JSON contract (consumed by the MapLibre/Vue map).
# Pure transformation of config + a yml title lookup -- no DB -- so we can assert
# the exact output and freeze it against upgrade-induced changes.
class MapOverlaysSerializerTest < ActiveSupport::TestCase
  test 'serialize builds layer objects and appends the tile path when no queryString' do
    overlays = [{ id: 'wdpa', color: '#f00', type: 'tile',
                  layers: [{ url: 'http://tiles/', isPoint: false }] }]
    yml = { overlays: { wdpa: { title: 'WDPA layer' } } }

    assert_equal([
      {
        id: 'wdpa', color: '#f00', type: 'tile',
        title: 'WDPA layer',
        layers: [
          { id: 'wdpa_0', url: "http://tiles/#{TILE_PATH}", color: '#f00',
            type: 'tile', isPoint: false }
        ]
      }
    ], MapOverlaysSerializer.new(overlays, yml).serialize)
  end

  test 'serialize uses queryString instead of the tile path when present' do
    overlays = [{ id: 'oecm', color: '#0f0', type: 'wms', queryString: '?a=1',
                  layers: [{ url: 'http://wms/', isPoint: true }] }]
    yml = { overlays: { oecm: { title: 'OECM' } } }

    layer = MapOverlaysSerializer.new(overlays, yml).serialize.first[:layers].first
    assert_equal 'http://wms/?a=1', layer[:url]
    assert_equal true, layer[:isPoint]
  end

  test 'serialize falls back to an empty title when the overlay is not in the yml' do
    overlays = [{ id: 'unknown', color: '#00f', type: 'tile',
                  layers: [{ url: 'http://x/', isPoint: false }] }]
    yml = { overlays: {} }

    assert_equal '', MapOverlaysSerializer.new(overlays, yml).serialize.first[:title]
  end
end
