class ProtectedArea < ApplicationRecord
  include GeometryConcern

  has_and_belongs_to_many :countries
  has_and_belongs_to_many :countries_for_index, -> { select(:id, :name, :iso_3, :region_id).includes(:region_for_index) }, :class_name => 'Country'
  has_and_belongs_to_many :sub_locations
  has_and_belongs_to_many :sources

  has_many :networks_protected_areas, dependent: :destroy
  has_many :networks, through: :networks_protected_areas
  has_many :pame_evaluations
  has_many :story_map_links

  belongs_to :legal_status
  belongs_to :iucn_category
  belongs_to :governance
  belongs_to :management_authority
  belongs_to :no_take_status
  belongs_to :designation
  delegate :jurisdiction, to: :designation, allow_nil: true
  belongs_to :wikipedia_article
  belongs_to :green_list_status

  after_create :create_slug

  scope :all_except, -> (pa) { where.not(id: pa) }

  scope :oecms, -> { where(is_oecm: true) }
  scope :wdpas, -> { where(is_oecm: false) }

  scope :terrestrial_areas, -> {
    where(marine: false)
  }

  scope :marine_areas, -> {
    where(marine: true)
  }

  scope :green_list_areas, -> {
    where.not(green_list_status_id: nil)
  }

  scope :most_protected_marine_areas, -> (limit) {
    where("gis_marine_area IS NOT NULL").
    order(gis_marine_area: :desc).limit(limit)
  }

  scope :least_protected_marine_areas, -> (limit) {
    where("gis_marine_area IS NOT NULL").
    order(gis_marine_area: :asc).limit(limit)
  }

  scope :most_recent_designations, -> (limit) {
    where("legal_status_updated_at IS NOT NULL").order(legal_status_updated_at: :desc).limit(limit)
  }

  scope :without_proposed, -> {
    where.not(legal_status_id: 4)
  }

  scope :with_pame_evaluations, -> {
    includes(:pame_evaluations).where.not(pame_evaluations: {id: nil})
  }

  def self.most_visited(date, limit=3)
    year_month = date.strftime("%m-%Y")
    opts = {with_scores: true, limit: [0, limit]}

    results = $redis.zrevrangebyscore(year_month, "+inf", "-inf", opts)
    results.map { |wdpa_id, visits|
      {
        protected_area: ProtectedArea.find_by_wdpa_id(wdpa_id),
        visits: visits.to_i
      }
    }
  end

  def self.green_list_protected_percentage
    (green_list_total_km / Stats::Global.global_area * 100).to_f.round(2)
  end

  def self.green_list_total_km
    green_list_areas.inject(0) { |_sum, pa| _sum + pa.gis_area }
  end

  def is_green_list
    green_list_status_id.present?
  end

  def wdpa_ids
    wdpa_id
  end

  def as_indexed_json options={}
    self.as_json(
      only: [:id, :wdpa_id, :name, :original_name, :marine, :has_irreplaceability_info, :has_parcc_info, :is_green_list, :is_oecm,
      :is_transboundary],
      methods: [:coordinates],
      include: {
        countries_for_index: {
          only: [:name, :id, :iso_3],
          include: { region_for_index: { only: [:id, :name] } }
        },
        sub_locations: { only: [:english_name] },
        iucn_category: { only: [:id, :name] },
        designation: { only: [:id, :name] },
        governance: { only: [:id, :name] }
      }
    )
  end

  def as_api_feeder
    attributes = self.as_json(
      only: [:wdpa_id, :name, :original_name, :marine, :legal_status_updated_at, :reported_area]
    )

    relations = {
      sub_locations: sub_locations.map{|sl| {english_name: sl.try(:english_name)}},
      countries: countries_for_index.map {|c| {'name' => c.try(:name), 'iso_3' => c.try(:iso_3), 'region' => {'name' => c.try(:region_for_index).try(:name)}}},
      iucn_category: {'name' => iucn_category.try(:name)},
      designation: {'name' => designation.try(:name), 'jurisdiction' => {'name' => designation.try(:jurisdiction).try(:name)}},
      legal_status: {'name' => legal_status.try(:name)},
      governance: {'name' => governance.try(:name)},
      networks_no: networks.count,
      designations_no: networks.detect(&:designation).try(:protected_areas).try(:count) || 0
    }.as_json

    relations.merge attributes
  end

  def bounds
    [
      [bounding_box["min_y"], bounding_box["min_x"]],
      [bounding_box["max_y"], bounding_box["max_x"]]
    ]
  end

  def coordinates
    [the_geom_longitude.to_f, the_geom_latitude.to_f]
  end

  def nearest_protected_areas
    @nearest_pas ||= Search.search('', {
      size: 3,
      filters: {location: {coords: coordinates}},
      sort: {geo_distance: coordinates}
    }).results
  end

  def overlap(pa)
    overlap = db.execute(overlap_query(pa)).first
    overlap["percentage"] = (overlap["percentage"].to_f*100).to_i
    overlap["sqm"] = (overlap["sqm"].to_f / 1000000).round(2)
    overlap
  end

  def self.global_terrestrial_oecm_coverage
    land_oecms = self.oecms.terrestrial_areas.pluck(:reported_area)
    total_oecm_area = land_oecms.inject(0) { |sum, area| sum + area.to_i }
    ((total_oecm_area.to_f / CountryStatistic.global_land_area.to_f) * 100).round(2)
  end

  def self.global_marine_oecm_coverage
    marine_oecms = self.oecms.marine_areas.pluck(:reported_marine_area)
    total_oecm_area = marine_oecms.inject(0) { |sum, area| sum + area.to_i }
    ((total_oecm_area.to_f / CountryStatistic.global_marine_area.to_f) * 100).round(2)
  end

  def self.global_marine_coverage
    reported_areas = marine_areas.pluck(:reported_marine_area)
    reported_areas.inject(0){ |sum, area| sum + area.to_i }
  end

  def self.sum_of_most_protected_marine_areas
    reported_areas = without_proposed.most_protected_marine_areas(20).map(&:gis_marine_area)
    reported_areas.inject(0){ |sum, area| sum + area.to_i }
  end

  def self.transboundary_sites    
    ProtectedArea.joins(:countries)
    .group('protected_areas.id')
    .having('COUNT(countries_protected_areas.country_id) > 1')
  end

  def is_transboundary
    self.countries.count > 1
  end
  
  def extent_url
    layer_number = is_point? ? 0 : 1

    {
      url: "#{MapHelper::WDPA_FEATURE_SERVER_URL}/#{layer_number}/query?where=wdpaid+%3D+%27#{wdpa_id}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson",
      padding: 1
    }
  end

  private

  def is_point?
    the_geom.geometry_type.type_name.match('Point').present?
  end

  def bounding_box_query
    dirty_query = """
      SELECT ST_XMax(extent) AS max_x,
             ST_XMin(extent) AS min_x,
             ST_YMax(extent) AS max_y,
             ST_YMin(extent) AS min_y
      FROM (
        SELECT ST_Extent(pa.the_geom) AS extent
        FROM protected_areas pa
        WHERE wdpa_id = ?
      ) e
    """.squish

    ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, wdpa_id
    ])
  end

  def overlap_query(pa)
    dirty_query = """
      SELECT
        CASE ST_AREA(a)
          WHEN '0' THEN '0'
          ELSE ST_AREA(ST_INTERSECTION(ST_MakeValid(a),ST_MakeValid(b)))/ST_AREA(ST_MakeValid(a))
        END AS percentage,
        ST_AREA(ST_INTERSECTION(ST_MakeValid(a),ST_MakeValid(b))::geography) AS sqm
      FROM (
        SELECT ST_SimplifyPreserveTopology(pa1.the_geom, 0.003) AS a, ST_SimplifyPreserveTopology(pa2.the_geom, 0.003) AS b
        FROM protected_areas AS pa1, protected_areas AS pa2
        WHERE pa1.wdpa_id = ? AND pa2.wdpa_id = ?
      ) AS intersection;
    """.squish

    ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, wdpa_id, pa.wdpa_id
    ])
  end

  def bounding_box
    @bounding_box ||= db.execute(bounding_box_query).first
    @bounding_box.each { |key,str| @bounding_box[key] = str.to_f }
  end

  def create_slug
    updated_slug = [name, designation.try(:name)].join(' ').parameterize
    update_attributes(slug: updated_slug)
  end

  def db
    ActiveRecord::Base.connection
  end

  def self.with_valid_iucn_categories
    valid_categories = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
    joins(:iucn_category).where(
      "iucn_categories.name IN (#{valid_categories})"
    )
  end




end
