class CartoDb::Importer
  include HTTMultiParty

  def initialize username, api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v1/imports/"
    @options = { query: { api_key: api_key } }
  end

  def import filename
    import_id = start_import filename
    return import_complete import_id
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
    return JSON.parse(response.body)["item_queue_id"]
  end
end
