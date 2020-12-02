class StatisticPresenter
  def initialize model
    @model          = model
    @statistic      = model.statistic
    @pame_statistic = model.pame_statistic
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

  def percentage_total_pa_cover
    perc = ((pa_land_area + pa_marine_area).to_f / ( land_area + marine_area ) * 100).round(2)
    # force percentage to be between 0 and 100!
    if (perc > 100)
      return 100
    elsif (perc < 0)
      return 0
    else
      return perc
    end
  end

  def nr_report_url
    (@statistic.send(:nr_report_url) || '') rescue ''
  end

  def method_missing method
    @model.send(method) rescue (@statistic.send(method) || 0) rescue 0
  end

  ["land", "marine"].each do |land_type|
    stat = "percentage_pa_#{land_type}_cover".to_sym
    define_method(stat) do
      (@statistic.send(stat) && @statistic.send(stat) > 100.0) ? 100.0 : (@statistic.send(stat) || 0) rescue 0
    end

    nr_stat = "percentage_nr_#{land_type}_cover".to_sym
    define_method(nr_stat) do
      (@statistic.send(nr_stat) && @statistic.send(nr_stat) > 100.0) ? 100.0 : @statistic.send(nr_stat).round(0) rescue nil
    end
    
    percent_oecm_stat = "percentage_oecms_pa_#{land_type}_cover".to_sym
    define_method(percent_oecm_stat) do
      (@statistic.send(percent_oecm_stat) && @statistic.send(percent_oecm_stat) > 100.0) ? 100.0 : @statistic.send(percent_oecm_stat) rescue nil
    end
  end

  private

  def global_statistic
    @global_statistic ||= Region.where(iso: 'GL').first.try(:regional_statistic)
  end
end
