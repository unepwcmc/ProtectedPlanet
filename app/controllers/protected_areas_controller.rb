class ProtectedAreasController < ApplicationController
  after_action :record_visit
  after_action :enable_caching

  def show
    id = params[:id]
    @protected_area = ProtectedArea.
      where("slug = ? OR wdpa_id = ?", id, id.to_i).
      first

    @protected_area or raise_404

    @presenter = ProtectedAreaPresenter.new @protected_area
    @countries = @protected_area.countries.without_geometry
    @other_designations = load_other_designations
    @networks = load_networks

    @wikipedia_article = @protected_area.try(:wikipedia_article)

    @attributes = [
      {
        title: 'Original Name',
        value: @protected_area.original_name
      },
      {
        title: 'English Designation',
        value: @protected_area.designation.try(:name) || "Not Reported"
      },
      {
        title: 'IUCN Management Category',
        value: @protected_area.iucn_category.try(:name) || "Not Reported"
      },
      {
        title: 'Status',
        value: @protected_area.legal_status.try(:name) || "Not Reported"
      },
      {
        title: 'Type of Designation',
        value: @protected_area.designation.try(:jurisdiction).try(:name) || "Not Reported"
      },
      {
        title: 'Status Year',
        value: @protected_area.legal_status_updated_at.try(:strftime, '%Y') || "Not Reported"
      },
      {
        title: 'Sublocation',
        value: @protected_area.sub_locations.map(&:iso).join(', ')
      },
      {
        title: 'Governance Type',
        value: @protected_area.governance.try(:name) || "Not Reported"
      },
      {
        title: 'Management Authority',
        value: @protected_area.management_authority.try(:name) || "Not Reported"
      },
      {
        title: 'Management Plan',
        value: 'TODO'
        # value: parse_management_plan(@protected_area.management_plan)
      },
      {
        title: 'International Criteria',
        value: @protected_area.international_criteria || "Not Reported"
      }
    ]

    @external_links = [
      {
        title: 'View more',
        image_url: ActionController::Base.helpers.image_url('logos/green-list.png'),
        link_title: "View the Green List page for #{@protected_area.name}",
        url: '' ##TODO links needed from CSV provided by IUCN.
      },
      {
        title: 'View more',
        image_url: ActionController::Base.helpers.image_url('logos/parcc.png'),
        link_title: "View the climate change vulnerability assessments for #{@protected_area.name}",
        link_url: '' #TODO make below work
        #link_url: url_for_related_source('parcc_info', @protected_area)
      }
    ]

    @locations = get_locations

    # @protected_area.sources
    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]

    @wdpa_other = [] ## 3 other PAs from ...?








    respond_to do |format|
      format.html
      format.pdf {
        rasterizer = Rails.root.join("vendor/assets/javascripts/rasterize.js")
        url = url_for(action: :show, id: @protected_area.wdpa_id, for_pdf: true)
        dest_pdf = Rails.root.join("tmp/#{@protected_area.wdpa_id}-site.pdf").to_s

        `phantomjs #{rasterizer} '#{url}' #{dest_pdf} A4`
        send_file dest_pdf, type: 'application/pdf'
      }
    end
  end

  private

  def get_locations
    locations = []
    
    if @countries.any?
      @countries.each_with_index do |country, i|
        locations << ActionController::Base.helpers.link_to(country.name, country_path(country.iso))
      end
    else
      locations << 'Areas Beyond National Jurisdiction'
    end
    
    locations.join(', ')
  end

  def record_visit
    return if @protected_area.nil?

    year_month = DateTime.now.strftime("%m-%Y")
    $redis.zincrby(year_month, 1, @protected_area.wdpa_id)
  end

  def load_other_designations
    other_designations = @protected_area.networks.detect(&:designation).try(:protected_areas)

    other_designations = Array.wrap(other_designations)
    other_designations.reject { |pa| pa.id == @protected_area.id }
  end

  TRANSBOUNDARY_SITES = "Transboundary sites".freeze
  def load_networks
    networks = @protected_area.networks.reject(&:designation)
    # ensure that transboundary sites network always appears first
    networks.sort { |a,b| a.name == TRANSBOUNDARY_SITES ? -1 : a.name <=> b.name }
  end
end
