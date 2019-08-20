class BaseSerializer
  ARGUMENT_ERROR_MESSAGE= 'data input is not of type ActiveRecord::Relation'.freeze

  def initialize(model, data=nil)
    @model = model
    @data = data
    sanitise_data
  end

  def serialize
    # Use input data if present, otherwise use all records of model
    source = data || model.all
    serialized_data = []
    # Loop through records
    source.map do |record|
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
      serialized_data << hash
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
end
