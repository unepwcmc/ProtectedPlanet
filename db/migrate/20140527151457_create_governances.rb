class CreateGovernances < ActiveRecord::Migration
  def change
    create_table :governances do |t|
      t.string :name

      t.timestamps
    end
  end
end
