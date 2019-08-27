class Aichi11Target < ActiveRecord::Base
  validates_inclusion_of :singleton_guard, :in => [0]

  def self.instance
    first || import
  end

  private

  def self.import
    CSV.foreach(aichi11_target_csv_path, headers: true) do |row|
      return create({}.merge(row))
    end
  end

  def self.aichi11_target_csv_path
    Rails.root.join('lib/data/seeds/aichi11_targets.csv')
  end
end
