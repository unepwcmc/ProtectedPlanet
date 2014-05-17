class CartoDb::Importer
  include HTTMultiParty
  require 'gdal-ruby/ogr'

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v1/imports/"
    @options = { query: { api_key: api_key } }
  end

  def import filename
    import_id = start_import filename

    unless import_id.nil?
      return import_complete import_id
    end

    return false
  end

  private

  def status import_id
    response = self.class.get("/#{import_id}", @options)
    return JSON.parse(response.body)["state"]
  end

  def import_complete import_id
    while state = status(import_id) do
      if ['complete', 'failure'].include? state
        return state == 'complete'
      end
    end
  end

  def start_import filename
    options = @options.merge({
      file: File.open(filename, 'r'),
      detect_mime_type: true
    })

    response = self.class.post("/", options)

    if response.nil?
      return
    else
      return JSON.parse(response.body)["item_queue_id"]
    end
  end
end
