class MapOverlaysSerializer

  def initialize(overlays, yml)
    @overlays = overlays
    @yml = yml
  end

  def serialize
    @overlays.map do |overlay|
      overlay.merge({
        title: @yml[:overlays][overlay[:id].to_sym][:title],
        layers: get_layers(overlay)      
      })
    end
  end

  private

  def get_layers(overlay)
    max_index = overlay[:layers].count-1

    (0..max_index).map{ |i| get_layer(overlay, i) }
  end

  def get_layer(overlay, index)
    {
      id: "#{overlay[:id]}_#{index}",
      url: overlay[:layers][index]
    }
  end
end
