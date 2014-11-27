class Download::Requesters::General < Download::Requesters::Base
  def initialize token
    @token = token
  end

  def request
    generation_status = $redis.get(download_key)
    JSON.parse(generation_status) rescue {}
  end

  private

  def download_key
    "downloads:general:#{@token}"
  end
end
