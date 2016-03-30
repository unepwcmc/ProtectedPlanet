class Wdpa::ProtectedAreaImporter::AttributeImporter
  def self.import _release
    size = 1000

    ["standard_polygons", "standard_points"].each do |table|
      total_pas = db.select_value("SELECT count(*) FROM #{table}").to_f
      pieces = (total_pas/size).ceil

      (0...pieces).each do |piece|
        ImportWorkers::ProtectedAreasImporter.perform_async(table, size, piece*size)
      end
    end

    # wait for all imports to be taken
    while Sidekiq::Queue.new("import").count > 0
      sleep 10000
    end

    # wait for all worker (but itself) to finish
    while Sidekiq::Workers.new.size > 1
      sleep 10000
    end

    return true
  end

  private

  def self.db
    ActiveRecord::Base.connection
  end
end
