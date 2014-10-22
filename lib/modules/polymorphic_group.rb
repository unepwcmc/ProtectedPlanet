module PolymorphicGroup
  class PolymorphicArray < Array
    def initialize model
      @model = model
      super 0
    end

    def << item
      @model.send(item.class.name.underscore.pluralize.to_sym) << item
    end
  end

  def self.included base
    base.extend ClassMethods
  end

  module ClassMethods
    def polymorphic_group group_name, relations
      define_method(group_name) do
        group = PolymorphicGroup::PolymorphicArray.new(self)
        relations.each do |relation|
          group.concat(Array.wrap(self.send(relation)))
        end

        group
      end
    end

  end
end
