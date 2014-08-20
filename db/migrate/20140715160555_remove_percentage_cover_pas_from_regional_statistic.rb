class RemovePercentageCoverPasFromRegionalStatistic < ActiveRecord::Migration
  def change
    remove_column :regional_statistics, :percentage_cover_pas, :string
  end
end
