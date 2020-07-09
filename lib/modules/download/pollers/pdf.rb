class Download::Pollers::Pdf
  def self.poll token
    Download::Utils.properties Download::Utils.key('pdf', token)
  end
end