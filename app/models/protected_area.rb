class ProtectedArea < ActiveRecord::Base
  include GeometryConcern

  has_and_belongs_to_many :countries
  has_and_belongs_to_many :countries_for_index, -> { select(:id, :name, :iso_3, :region_id).includes(:region_for_index) }, :class_name => 'Country'
  has_and_belongs_to_many :sub_locations
  has_and_belongs_to_many :sources

  has_many :networks_protected_areas, dependent: :destroy
  has_many :networks, through: :networks_protected_areas

  belongs_to :legal_status
  belongs_to :iucn_category
  belongs_to :governance
  belongs_to :management_authority
  belongs_to :no_take_status
  belongs_to :designation
  delegate :jurisdiction, to: :designation, allow_nil: true
  belongs_to :wikipedia_article

  after_create :create_slug

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

  def wdpa_ids
    wdpa_id
  end

  def as_indexed_json options={}
    self.as_json(
      only: [:id, :wdpa_id, :name, :original_name, :marine, :has_irreplaceability_info, :has_parcc_info],
      methods: [:coordinates],
      include: {
        countries_for_index: {
          only: [:name, :id],
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

  def percentage_overlap(pa)
    percentage = db.execute(percentage_overlap_query(pa)).first["percentage"]
    (percentage.to_f*100).to_i # WARNING to_i ignores very small percentages of overlap
  end

  def sqm_overlap(pa)
    sqm = db.execute(percentage_overlap_query(pa)).first["sqm"]
    (sqm.to_f / 1000000).round(2)
  end

  private

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

  def percentage_overlap_query(pa)
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
