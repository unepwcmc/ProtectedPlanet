class ProtectedArea < ApplicationRecord

  # Emergency fix: These Protected Areas in disputed territories should not be shown.
  # IDs are used in the ProtectedAreasController to raise a not found exception.
  # TODO: Ticket https://unep-wcmc.codebasehq.com/projects/protected-planet-support-and-maintenance/tickets/326
  PROHIBITED_WDPA_IDS = [
    555707156,
    555706619,
    555706626,
    555707151,
    555706102,
    555706547,
    555706563,
    555706684,
    555706625,
    555707170,
    555706683,
    555706620,
    555706621,
    555706623,
    555706648,
    555707143,
    555706624,
    555707142,
    555706654,
    555706800,
    555706627,
    555705980,
    555706798,
    555705974,
    555706617,
    555707169,
    555706546,
    555706622,
    555707201,
    555707310,
    555707330,
    555707400,
    555707403,
    555707407,
    555707408,
    555707429,
    555707432,
    555707435,
    555707444,
    555707448,
    555707605,
    555707614,
    555707629,
    555707953,
    555707984,
    555707996,
    555708006,
    555708040,
    555708049,
    555708197,
    555708212,
    555708278,
    555708309,
    555708315,
    555708363,
    555708380,
    555708429,
    555708445,
    555708500,
    555708568,
    555708571,
    555708582,
    555708610,
    555708613,
    555708615,
    555708618,
    555708633,
    555708843,
    555708889,
    555709016,
    555709465,
    555709466,
    555709491,
    555709501,
    555709503,
    555709513,
    555709520,
    555709554,
    555709556,
    555709567,
    555709722,
    555709807,
    555710420,
    555710996,
    555711034,
    555711166,
    555711172,
    555711195,
    555711233,
    555711234,
    555711332,
    555711334,
    555711335,
    555711402,
    555711430,
    555711545,
    555711630,
    555712356,
    555712369,
    555712370,
    555712371,
    555712372,
    555712373,
    555712374,
    555712375,
    555712376,
    555712377,
    555712378,
    555712379,
    555712511,
    555712512,
    555712513,
    555712520,
    555712540,
    555712544,
    555712545,
    555712671,
    555712734,
    555712736,
    555712867,
    555713984,
    555714307,
    555714366,
    555714787,
    555714969,
    555714988,
    555714997,
    555715001,
    555715003
  ]

  include GeometryConcern
  include SourceHelper

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

  scope :non_candidate_green_list_areas, -> {
    includes(:green_list_status)
    .where.not(green_list_statuses: {status: 'Candidate'}, green_list_status_id: nil)
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

  def is_green_list
    green_list_status&.status.in?(['Green Listed', 'Relisted'])
  end

  def is_green_list_candidate
    green_list_status&.status == 'Candidate'
  end

  def self.greenlist_coverage_growth(start_year = 0)
    # Is in this format: [{year: year, value: area}...]
    # Takes an optional start year from which to start counting
    growth = <<-SQL
      SELECT DISTINCT ON(t.year) JSON_BUILD_OBJECT(
        'year', t.year, 'value', t.area
      ) AS data
      FROM (
        SELECT pa.legal_status_updated_at AS year,
              SUM(pa.gis_area) OVER(ORDER BY pa.legal_status_updated_at) AS area
        FROM protected_areas pa
        JOIN green_list_statuses gls ON gls.id = pa.green_list_status_id
        WHERE gls.status <> 'Candidate'
        ORDER BY year
      ) t
      WHERE EXTRACT(YEAR FROM t.year) >= ?
    SQL

    result = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.send(:sanitize_sql_array, [
        growth, start_year
      ])
    )

    result.map { |r| JSON.parse(r['data']) }
  end

  def sources_per_pa
    sources = ActiveRecord::Base.connection.execute("""
      SELECT sources.title, EXTRACT(YEAR FROM sources.update_year) AS year, sources.responsible_party
      FROM sources
      INNER JOIN protected_areas_sources
      ON protected_areas_sources.protected_area_id = #{self.id}
      AND protected_areas_sources.source_id = sources.id
      """)
      # Helper method
    convert_into_hash(sources.uniq)
  end

  def wdpa_ids
    wdpa_id
  end

  def as_indexed_json options={}
    self.as_json(
      only: [:id, :wdpa_id, :name, :original_name, :marine, :has_irreplaceability_info, :has_parcc_info, :is_oecm],
      methods: [:coordinates, :special_status],
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

  def special_status
    [
      ({ name: 'is_green_list' } if is_green_list),
      ({ name: 'is_green_list_candidate' } if is_green_list_candidate),
      ({ name: 'has_parcc_info' } if has_parcc_info),
      ({ name: 'is_transboundary' } if is_transboundary)
    ].compact
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
    countries.count > 1
  end

  def arcgis_layer_config
    {
      layers: [{url: arcgis_layer, isPoint: is_point?}],
      color: layer_color,
      queryString: arcgis_query_string
    }
  end

  def layer_color
    if is_oecm
      OVERLAY_YELLOW
    elsif marine
      OVERLAY_BLUE
    else
      OVERLAY_GREEN
    end
  end

  def arcgis_layer
    if is_oecm
      is_point? ? OECM_POINT_LAYER_URL : OECM_POLY_LAYER_URL
    else
      is_point? ? WDPA_POINT_LAYER_URL : WDPA_POLY_LAYER_URL
    end
  end

  def arcgis_query_string
    "/query?where=wdpaid+%3D+#{wdpa_id}&geometryType=esriGeometryEnvelope&returnGeometry=true&f=geojson"
  end

  def extent_url
    {
      url: "#{arcgis_layer}/query?where=wdpaid+%3D+#{wdpa_id}&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson",
      padding: 0.2
    }
  end

  def is_whs?
    designation.name == 'World Heritage Site (natural or mixed)'
  end

  private

  def is_point?
    @is_point ||= begin
      extent = bounds
      extent[0][0] == extent[1][0] && extent[0][1] == extent[1][1]
    end
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
    updated_slug = [wdpa_id, name, designation.try(:name)].join(' ').parameterize
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
