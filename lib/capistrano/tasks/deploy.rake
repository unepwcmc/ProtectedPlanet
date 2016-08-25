namespace :deploy do
  desc 'Restart sidekiq'
  task :restart do
    on roles(:util) do
      execute 'sudo service sidekiq stop'
      execute 'sudo service sidekiq start'
    end
  end
  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        with :rails_env => fetch(:stage) do
          execute :rake, 'cache:clear'
        end
      end
    end
  end
end

namespace :maintenance do
  desc 'Turn on maintenance mode'
  task :on do
    on roles(:web), in: :sequence, wait: 5 do
      within current_path do
        with :rails_env => fetch(:stage) do
          execute :rake, 'maintenance:start allowed_paths="/admin/maintenance"'
        end
      end
    end
  end

  desc 'Turn off maintenance mode'
  task :off do
    on roles(:web), in: :sequence, wait: 5 do
      within current_path do
        with :rails_env => fetch(:stage) do
          execute :rake, 'maintenance:end'
        end
      end
    end
  end
end

