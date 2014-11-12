module ProjectsHelper
  def class_to_human classname
    case classname.name
    when 'SavedSearch'
      'Search'
    when 'ProtectedArea'
      'Protected Area'
    else
      classname
    end
  end

  def show_item_path item
    case item
    when SavedSearch
      search_path(q: item.name)
    when Country
      country_stats_path(item.iso)
    when Region
      regional_stats_path(item)
    when ProtectedArea
      protected_area_path(item.slug)
    else
      root_path
    end
  end
end
