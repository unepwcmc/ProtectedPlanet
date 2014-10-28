module ApplicationHelper
  def commaify number
    number_with_delimiter(number, delimeter: ',')
  end

  def mapbox_url geojson, size
    mapbox_config = Rails.application.secrets.mapbox
    mapbox_path = "geojson(#{geojson})/auto/#{size[:x]}x#{size[:y]}.png"
    mapbox_path << "?access_token=#{mapbox_config['access_token']}"

    File.join(mapbox_config['base_url'], mapbox_path)
  end
end
