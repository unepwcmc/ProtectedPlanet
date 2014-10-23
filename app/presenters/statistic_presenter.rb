class StatisticPresenter
  def initialize model
    @model = model
    @statistic = model.statistic
  end

  def percentage_of_global_pas
    percentage = (@statistic.pa_area / global_statistic.pa_area) * 100
    '%.1f' % percentage
  rescue
    "0"
  end

  def method_missing method
    @model.send(method) rescue @statistic.send(method).round rescue nil
  end

  private

  def global_statistic
    @global_statistic ||= Region.where(iso: 'GL').first.regional_statistic
  end
end
