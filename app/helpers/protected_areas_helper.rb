# frozen_string_literal: true

module ProtectedAreasHelper
  def map_bounds(protected_area = nil)
    unless protected_area
      return Rails.application.secrets.default_map_bounds.stringify_keys
    end

    {
      'from' => protected_area.bounds.first,
      'to' => protected_area.bounds.last
    }
  end

  # as of 04Apr it doesn't seem to be used
  # def related_links? protected_area
  #   !!protected_area.wikipedia_article
  # end

  def completion_attribute(label, complete)
    if complete
      content_tag(:li, class: 'complete') do
        icon = content_tag(:i, '', class: 'fa fa-check')
        raw "#{icon} #{label}"
      end
    else
      content_tag(:li, label, class: 'non-complete')
    end
  end

  def reported_area
    # We add up all reported_area in all parcels
    parcels_including_protected_area_self = @protected_area.parcels_including_protected_area_self
    reported_area_km = 0
    parcels_including_protected_area_self.each do |pa|
      reported_area_km += pa.reported_area.to_f
    end
    reported_area_km&.nonzero? ? "#{reported_area_km.round(2)} km&sup2;".html_safe : 'Not Reported'
  end

  def pame_evaluations_summary
    grouped_evaluations = @protected_area.pame_evaluations.group_by(&:methodology)
    grouped_evaluations.update(grouped_evaluations) do |_, evaluations|
      evaluations.map { |ev| ev.year == 0 ? 'Not Reported' : ev.year }
    end
  end

  def has_pame_statistics_for(presenter, area = :land)
    # Ensures pame stats are returned only for Country pages / Statistic presenters
    presenter.class == StatisticPresenter && presenter.pame_statistic &&
      presenter.pame_statistic.send("pame_percentage_pa_#{area}_cover").present? &&
      presenter.pame_statistic.send("pame_pa_#{area}_area").present?
  end

  MP_DOCUMENTS = {
    9786 => 'https://wdpa.s3.amazonaws.com/Country_informations/MYS/Pulau_Redang_9786.pdf',
    555_635_837 => 'https://wdpa.s3.amazonaws.com/Country_informations/MYS/Pulau_Tinggi_and_Sibu_555635837.pdf',
    3150 => 'https://wdpa.s3.amazonaws.com/Country_informations/MYS/Pulau_Tioman_3150.pdf'
  }.freeze
  def management_plan_document
    MP_DOCUMENTS[@protected_area.site_id]
  end

  def area_type_is
    if @protected_area.is_oecm
      'oecm'
    elsif @protected_area.marine
      'marine_pa'
    else
      'pa'
    end
  end

  def map_layer_type
    case area_type_is
    when 'oecm'
      I18n.t('map.overlays.oecm.title')
    when 'marine_pa'
      I18n.t('map.overlays.marine_wdpa.title')
    else
      I18n.t('map.overlays.terrestrial_wdpa.title')
    end
  end
  
  def stats_attributes_set_description
    case area_type_is
    when 'oecm'
      I18n.t('stats.attributes.description.oecm')
    when 'marine_pa'
      I18n.t('stats.attributes.description.marine_pa')
    else
      I18n.t('stats.attributes.description.pa')
    end
  end
end
