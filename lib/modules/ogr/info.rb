require 'json'
require 'open3'
require 'shellwords'

# Reads layer metadata out of a geospatial file (.gdb, .shp, ...).
#
# This used to bind the `gdal` Ruby gem (`require 'gdal-ruby/ogr'`), which is
# pinned to `~> 2.0` and only compiles against GDAL 2.x — it calls C API
# functions (OSRStripCTParms, OSRFixup, OPTGetParameterInfo, ...) that were
# removed in GDAL 3. Since the image moved to GDAL 3.8.4 for OpenFileGDB, that
# gem can no longer build.
#
# Everything this class ever needed — layer count, layer names, feature count —
# is available from the `ogrinfo` CLI that ships with gdal-bin, so it shells out
# instead. `-json` output has been available since GDAL 3.7.
class Ogr::Info
  class OgrInfoError < StandardError; end

  def initialize(filename)
    @filename = filename
  end

  def layer_count
    layers.count
  end

  def layers
    @layers ||= dataset_json.fetch('layers', []).map { |l| l['name'] }
  end

  def layers_matching(regex)
    layers.select { |layer| !!(layer =~ regex) }
  end

  def feature_count(layer_name)
    json = ogrinfo_json('-so', @filename, layer_name.to_s)
    layer = json.fetch('layers', []).first
    raise OgrInfoError, "No such layer #{layer_name} in #{@filename}" if layer.nil?

    layer['featureCount']
  end

  private

  def dataset_json
    @dataset_json ||= ogrinfo_json(@filename)
  end

  def ogrinfo_json(*args)
    cmd = ['ogrinfo', '-json', *args]
    stdout, stderr, status = Open3.capture3(*cmd)

    unless status.success?
      raise OgrInfoError, "#{cmd.shelljoin} failed: #{stderr.strip}"
    end

    JSON.parse(stdout)
  rescue JSON::ParserError => e
    raise OgrInfoError, "#{cmd.shelljoin} returned unparseable JSON: #{e.message}"
  end
end
