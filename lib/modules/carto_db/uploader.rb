class CartoDb::Uploader
  include HTTMultiParty
  default_timeout 1800
  require 'gdal-ruby/ogr'

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v1/imports/"
    @options = { query: { api_key: api_key } }
  end

  def upload filename
    upload_id = start_upload filename

    unless upload_id.nil?
      return upload_complete upload_id
    end

    return false
  end

  private

  def status upload_id
    response = self.class.get("/#{upload_id}", @options)
    return JSON.parse(response.body)["state"]
  end

  def upload_complete upload_id
    while state = status(upload_id) do
      if ['complete', 'failure'].include? state
        return state == 'complete'
      end

      sleep 5
    end
  end

  def start_upload filename
    options = @options.deep_merge({
      query: {
        file: File.open(filename, 'r'),
      },
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
