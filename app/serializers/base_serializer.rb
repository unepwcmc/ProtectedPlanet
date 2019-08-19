class BaseSerializer
  ARGUMENT_ERROR_MESSAGE= 'data input is not of type ActiveRecord::Relation'.freeze

  def initialize(model, data=nil)
    @model = model
    @data = data
    sanitise_data
  end

  def serialize
    source = data || model.all
    source.map(&:attributes).map do |d|
      d.slice(*fields)
    end
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

  private

  def sanitise_data
    if data && !data.is_a?(ActiveRecord::Relation)
      raise ArgumentError, ARGUMENT_ERROR_MESSAGE
    end
  end
end
