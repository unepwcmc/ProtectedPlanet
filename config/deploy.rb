# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'pp'
set :repo_url, 'https://github.com/unepwcmc/ProtectedPlanet.git'

set :branch, "master"

set :linked_files, %w{config/database.yml .env}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Whenever configuration
set :whenever_environment, -> { fetch(:stage) }
set :whenever_roles, [:util]

set :sidekiq_role, :util
set :sidekiq_default_hooks, false

set :migration_role, :util

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:web), in: :sequence, wait: 5 do
      invoke 'deploy:stop'
      invoke 'deploy:start'
    end
  end
  after :publishing, :restart

  desc 'Start application'
  task :start do
    on roles(:web), in: :sequence, wait: 5 do
      execute "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D -E #{fetch(:rails_env)}"
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:web), in: :sequence, wait: 5 do
      execute "kill -s QUIT `cat #{shared_path}/tmp/pids/unicorn.pid` || :"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        with :rails_env => fetch(:rails_env) do
          execute :rake, 'cache:clear'
        end
      end
    end
  end

  before :stop, :stop_monit do
    on roles(:all) do
      execute 'sudo service monit stop || :'
    end
  end

  after :stop, :stop_sidekiq do
    on roles(fetch(:sidekiq_role)) do
      execute 'sudo service sidekiq stop'
    end
  end
  after :restart, :start_sidekiq do
    on roles(fetch(:sidekiq_role)) do
      execute 'sudo service sidekiq start'
    end
  end

  after :start_sidekiq, :start_monit do
    on roles(:all) do
      execute 'sudo service monit start || :'
    end
  end

end

namespace :maintenance do

  desc 'Turn on maintenance mode'
  task :on do
    on roles(:web), in: :sequence, wait: 5 do
      within current_path do
        with :rails_env => fetch(:rails_env) do
          execute :rake, 'maintenance:start allowed_paths="/admin/maintenance"'
        end
      end
    end
  end

  desc 'Turn off maintenance mode'
  task :off do
    on roles(:web), in: :sequence, wait: 5 do
      within current_path do
        with :rails_env => fetch(:rails_env) do
          execute :rake, 'maintenance:end'
        end
      end
    end
  end
end

namespace :bower do
  desc 'Install bower packages'
  task :install do
    on roles(:web) do
      within release_path do
        execute :rake, 'bower:install CI=true'
      end
    end
  end
end
before 'deploy:compile_assets', 'bower:install'
