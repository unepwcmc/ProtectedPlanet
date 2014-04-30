class CreateProtectedAreas < ActiveRecord::Migration
  def change
    create_table :protected_areas do |t|

      t.timestamps
    end
  end
end
