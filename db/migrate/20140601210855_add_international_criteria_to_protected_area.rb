class AddInternationalCriteriaToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :international_criteria, :string
  end
end
