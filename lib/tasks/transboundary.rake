namespace :transboundary do
  desc 'Update transboundary status for the relevant sites'
  task :update => :environment do |t|
    transboundary_sites = ActiveRecord::Base.connection.execute("""
      SELECT pa.name, count(country_id) 
      FROM countries_protected_areas 
      JOIN protected_areas AS pa ON pa.id = protected_area_id 
      GROUP BY pa.name 
      HAVING count(country_id) > 1;
    """)

    existing_transboundaries = ProtectedArea.where.not(is_transboundary: true)

    transboundary_sites.each do |area|
      pa = existing_transboundaries.where(name: area['name']).first
      pa.is_transboundary = true
      pa.save
      puts "Marked #{pa.name} as a transboundary site"
    end
  end
end