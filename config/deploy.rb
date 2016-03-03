# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'ProtectedPlanet'
set :repo_url, 'github.com/unepwcmc/ProtectedPlanet.git'

set :branch, 'linode-deploy'

set :deploy_user, 'wcmc'
set :deploy_to, "/home/#{fetch(:deploy_user)}/#{fetch(:application)}"


set :whenever_environment, -> { fetch(:stage) }
set :whenever_roles, [:util]

set :migration_role, :util




set :rvm_type, :user
set :rvm_ruby_version, '2.2.3'

set :pty, true


set :ssh_options, {
  forward_agent: true,
}

set :linked_files, %w{config/database.yml .env}

set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

set :keep_releases, 5

set :passenger_restart_with_touch, false

