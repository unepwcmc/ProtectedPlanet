namespace :geom do
  desc "Normalize country bounding boxes"
  task normalize_country_bboxes: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Normalizing bounding boxes...."
    source = File.join(Rails.root, 'lib', 'data', 'seeds', 'adjusted_country_bboxes.csv')
    CSV.foreach(source, headers: true) do |row|
      attributes = row.to_hash
      country = Country.where(:iso_3 => attributes['iso_3']).first
      sql = "update countries set bounding_box = ST_GeomFromText('#{attributes['normalized_bounding_box']}') where iso_3 = '#{attributes['iso_3']}'"
      ActiveRecord::Base.connection.execute(sql) 
      logger.info "Updated #{country.name}."
    end

    logger.info "Bounding Boxes normalized."

  end
end

