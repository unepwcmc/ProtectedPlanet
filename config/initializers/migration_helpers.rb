ActiveRecord::Migration[5.0].class_eval do
  def view_sql(timestamp, view)
    File.read(Rails.root.join("db/views/#{view}/#{timestamp}.sql"))
  end
end
