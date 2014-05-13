class CartoDbImporter
  def initialize username: username, api_key: api_key
    @api_key = api_key
    @username = username
  end

  def import filename
    response = Typhoeus.post(
      "https://#{@username}.cartodb.com/api/v1/imports/", 
      params: {api_key: @api_key}, 
      body: {file: File.open(filename, 'r')}
    )

    return false unless response.response_code == 200

    item_queue_id = JSON.parse(response.body)["item_queue_id"]

    status = nil
    begin
      response = Typhoeus.get(
        "https://#{@username}.cartodb.com/api/v1/imports/#{item_queue_id}",
        params: {api_key: @api_key}
      )

      status = JSON.parse(response.body)["state"]
    end while status != 'complete' && status != 'failure'

    return status == 'complete'
  end
end