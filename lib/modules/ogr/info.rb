require 'gdal-ruby/ogr'

class Ogr::Info
  def initialize filename
    @driver = Gdal::Ogr.open filename
  end

  def layer_count
    @driver.get_layer_count
  end

  def layers
    layer_names = []
    @driver.get_layer_count.times do |layer_index|
      layer_names.push @driver.get_layer(layer_index).get_name
    end

    layer_names
  end

  def layers_matching regex
    layers.select do |layer|
      !!(layer =~ regex)
    end
  end

  def feature_count layer_name
    layer = @driver.get_layer(layer_name)
    layer.get_feature_count
  end
end
