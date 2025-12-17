class Download::Requesters::General < Download::Requesters::Base
  def initialize format, token
    @format = format
    @token = token
  end

  TYPES = %w(marine greenlist oecm wdpa).freeze
  def request
    enqueue_generation_once do
      DownloadWorkers::General.perform_async(@format, type, identifier)
    end

    json_response
  end

  def domain
    'general'
  end

  private

  def identifier
    @token
  end

  def type
    if TYPES.include?(identifier)
      identifier
    else
      (identifier.length == 2 ? "region" : "country")
    end
  end
end
