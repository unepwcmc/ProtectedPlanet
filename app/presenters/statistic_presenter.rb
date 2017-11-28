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

  def geometry_ratio
    @statistic.polygons_count ||= 0
    @statistic.points_count   ||= 0
    total = @statistic.polygons_count + @statistic.points_count

    {
      polygons: (((@statistic.polygons_count/total.to_f)*100).round rescue 0),
      points:   (((@statistic.points_count/total.to_f)*100).round   rescue 0),
    }
  end

  def method_missing method
    @model.send(method) rescue (@statistic.send(method) || 0) rescue 0
  end

  ["land", "marine"].each do |type|
    stat = "percentage_pa_#{type}_cover".to_sym
    define_method(stat) do
      (@statistic.send(stat) && @statistic.send(stat) > 100.0) ? 100.0 : @statistic.send(stat)
    end
  end

  private

  def global_statistic
    @global_statistic ||= Region.where(iso: 'GL').first.try(:regional_statistic)
  end
end
