ActiveRecord::Migration[5.0].class_eval do
  def view_sql(timestamp, view)
    File.read(Rails.root.join("db/views/#{view}/#{timestamp}.sql"))
  end

  def function_sql(timestamp, function)
    File.read(Rails.root.join("db/functions/#{function}/#{timestamp}.sql"))
  end
end
