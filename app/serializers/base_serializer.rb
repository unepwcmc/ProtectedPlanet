class BaseSerializer
  ARGUMENT_ERROR_MESSAGE= 'data input is not of type ActiveRecord::Relation'.freeze

  def initialize(model, params, data=nil)
    @model = model
    @params = params
    @data = data
    @source = data || model.all
    sanitise_data
  end

  def serialize
    # Use input data if present, otherwise use all records of model
    serialized_data = {
      page: page,
      per_page: per_page,
      data: [],
      total: sorted.count
    }
    # Loop through records
    sorted_and_paginated.map do |record|
      hash = {}
      # Loop through selected associations and related fields
      relations.map do |relation, _fields|
        relation_obj = record.send(relation)
        # Skip if empty or not expected object
        next unless relation_obj.is_a?(relation.to_s.camelize.constantize)
        # Inject relation's fields
        _fields.each { |field| hash.merge!("#{field}" => relation_obj.send(field)) }
      end
      # Inject model fields
      fields.each { |field| hash.merge!("#{field}" => record.send(field)) }
      serialized_data[:data] << hash
    end
    serialized_data
  end

  protected

  def model
    @model
  end

  def data
    @data
  end

  def source
    @source
  end

  def fields
    raise NotImplementedError
  end

  def relations
    {}
  end

  private

  def sanitise_data
    if data && !data.is_a?(ActiveRecord::Relation)
      raise ArgumentError, ARGUMENT_ERROR_MESSAGE
    end
  end

  def sorted
    associations = relations.keys
    source.includes(associations)
      .order("#{sort_by} #{order} NULLS LAST")
      .references(associations)
  end

  def sorted_and_paginated
    sorted.limit(per_page).offset(per_page * (page - 1))
  end

  def sort_by
    @params[:sort_by]
  end

  def order
    @params[:order]
  end

  def page
    _page = @params[:page].to_i
    (_page && _page >= 1) ? _page : 1
  end

  def per_page
    _per_page = @params[:per_page].to_i
    (_per_page && _per_page >= 1) ? _per_page : 8
  end
end
