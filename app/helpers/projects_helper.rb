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
end
