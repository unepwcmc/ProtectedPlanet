class StatisticPresenter
  def initialize model
    @model = model
    @statistic = model.statistic
  end

  def percentage_of_global_pas
    percentage = (pa_area / global_statistic.pa_area) * 100
    '%.1f' % percentage
  rescue NoMethodError
    "0"
  end

  def percentage_pa_marine_cover
    percentage = percentage_pa_eez_cover + percentage_pa_ts_cover
    '%.1f' % percentage
  rescue NoMethodError
    "0"
  end

  def marine_area
    ts_area + eez_area
  end

  def method_missing method
    @model.send(method) rescue @statistic.send(method).round(2) rescue 0
  end

  private

  def global_statistic
    @global_statistic ||= Region.where(iso: 'GL').first.try(:regional_statistic)
  end
end
