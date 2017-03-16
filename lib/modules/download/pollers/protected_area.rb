class Download::Pollers::ProtectedArea
  def self.poll token
    Download::Utils.properties Download::Utils.key('protected_area', token)
  end
end

