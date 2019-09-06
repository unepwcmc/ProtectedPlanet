class Aichi11TargetSerializer < BaseSerializer
  PER_PAGE = 1.freeze

  def initialize(params={}, data=nil)
    super(Aichi11Target, params, data)
  end

  def serialize
    super
  end

  private

  def fields
    @model.column_names.reject do |attr|
      ['id', 'singleton_guard', 'created_at', 'updated_at'].include?(attr)
    end.map(&:to_sym)
  end

  def sort_by
    # This is only necessary to avoid an exception being thrown.
    # As there's only one record, sorting is not really necessary.
    super || 'coverage_marine'
  end

  def order
    super || 'desc'
  end

  def per_page_default
    PER_PAGE
  end
end
