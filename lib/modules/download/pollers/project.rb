class Download::Pollers::Project
  def self.poll token
    Download::Utils.properties Download::Utils.key('project', token)
  end
end

