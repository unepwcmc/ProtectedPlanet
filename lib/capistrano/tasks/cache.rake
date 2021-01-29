namespace :clear do
  desc 'clear rails cache'
  task :cache do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute :rake, "cache:clear"
        end
      end
    end
  end
end
