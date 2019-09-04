module MarineHelper
  def marine_stats(key)
    statistic = @marine_statistics[key]

    statistic == nil ? 0 : statistic
  end
end