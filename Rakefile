# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

Rails::TestTask.new("test:acceptance" => "test:prepare") do |t|
  t.pattern = "test/acceptance/**/*_test.rb"
end

Rake::Task["test:run"].enhance ["test:acceptance"]
