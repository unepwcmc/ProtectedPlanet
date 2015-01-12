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

  def method_missing method
    @model.send(method) rescue @statistic.send(method).round(2) rescue 0
  end

  private

  def global_statistic
    @global_statistic ||= Region.where(iso: 'GL').first.try(:regional_statistic)
  end
end
