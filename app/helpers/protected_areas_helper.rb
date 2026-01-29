# frozen_string_literal: true

module ProtectedAreasHelper
  # URL query parameter names (e.g. parcel selection)
  URL_PARAMS = { parcel: 'site_pid' }.freeze

  # Returns the protected area show URL, with optional parcel query param when site_pid is present.
  def pa_site_url_with_parcel(site_id, site_pid)
    return nil unless site_id
    opts = {}
    opts[URL_PARAMS[:parcel].to_sym] = site_pid if site_pid.present?
    Rails.application.routes.url_helpers.protected_area_path(site_id, opts)
  end

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

  # Returns PAME summaries grouped by parcel site_pid, so the frontend can
  # switch between parcels using the parcel dropdown.
  #
  # If a protected area has no explicit parcels, the PA itself is treated as a
  # single "parcel" via ProtectedArea#parcels_including_protected_area_self.
  #
  # Shape:
  # {
  #   "1234_1" => { "METT" => [2018, 2020], "RAPPAM" => [2015] },
  #   "1234_2" => { "METT" => [2019] }
  # }
  def current_pa_and_all_parcels_pame_evaluations_attributes
    @protected_area.parcels_including_protected_area_self.sort_by(&:site_pid).each_with_object({}) do |parcel, hash|
      evals = parcel.pame_evaluations
      next if evals.blank?

      grouped = evals.group_by { |evaluation| evaluation.pame_method&.name }
      hash[parcel.site_pid] = grouped.transform_values do |evaluations|
        evaluations.map { |ev| ev.asmt_year == 0 ? 'Not Reported' : ev.asmt_year }
      end
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

  def attributes_parcels_dropdown_descriptions
    case area_type_is
    when 'oecm'
      I18n.t('attributes.parcel_dropdown.description.oecm')
    when 'marine_pa'
      I18n.t('attributes.parcel_dropdown.description.marine_pa')
    else
      I18n.t('attributes.parcel_dropdown.description.pa')
    end
  end
end
