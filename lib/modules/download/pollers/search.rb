class Download::Pollers::Search
  def self.poll token
    Download::Utils.properties Download::Utils.key('search', token)
  end
end
