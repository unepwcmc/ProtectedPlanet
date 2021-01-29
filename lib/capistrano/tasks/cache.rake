namespace :cache do
  task :clear do
    on roles(:all) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rails, 'cache:clear'
        end
      end
    end
  end
end