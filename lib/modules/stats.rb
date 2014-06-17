class Stats
  def self.global_pa_count 
    ProtectedArea.count(:id)
  end
end