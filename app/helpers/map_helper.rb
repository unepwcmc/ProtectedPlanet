module MapHelper
  def map_legend
    [
      { theme: 'theme--terrestrial', title: I18n.t('map.overlays.terrestrial_wdpa.title') },
      { theme: 'theme--marine', title: I18n.t('map.overlays.marine_wdpa.title') },
      { theme: 'theme--oecm', title: I18n.t('map.overlays.oecm.title') }
    ]
  end
end