class Download::Pollers::General
  def self.poll token
    Download::Utils.properties Download::Utils.key('general', token)
  end
end
