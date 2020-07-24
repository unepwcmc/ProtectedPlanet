namespace :transboundary do
  desc 'Update transboundary status for the relevant sites'
  task :update => :environment do |t|
    transboundary_sites = ActiveRecord::Base.connection.execute("""
      SELECT *
      FROM protected_areas
      INNER JOIN (
        SELECT pa.name
        FROM countries_protected_areas 
        JOIN protected_areas AS pa ON pa.id = protected_area_id 
        GROUP BY pa.name
        HAVING count(country_id) > 1
      ) AS transboundary_pas ON transboundary_pas.name = protected_areas.name
      WHERE protected_areas.is_transboundary = false;
    """)

    transboundary_sites.update_all(is_transboundary: true)
  end
end