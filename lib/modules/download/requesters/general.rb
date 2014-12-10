class Download::Requesters::General < Download::Requesters::Base
  def initialize token
    @token = token
  end

  def request
    generation_info
  end

  def domain
    'general'
  end

  private

  def identifier
    @token
  end
end
