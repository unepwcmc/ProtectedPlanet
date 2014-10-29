module HomeHelper
  def nav_main_background_class controller_name
    if controller_name.downcase == 'home'
      'home-nav-main'
    end
  end
end
