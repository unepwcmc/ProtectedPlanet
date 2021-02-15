namespace :deploy do
    task :clear_cache do
        on roles(:app) do |host|
            with rails_env: fetch(:rails_env) do
                within current_path do
                    execute :rake, "cache:clear"
                end
            end
        end
    end
end
