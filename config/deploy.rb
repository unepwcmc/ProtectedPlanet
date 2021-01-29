# config valid only for current version of Capistrano
lock '3.11.0'

set :repo_url, 'git@github.com:unepwcmc/ProtectedPlanet.git'
set :application, "ProtectedPlanet"

set :deploy_user, 'wcmc'
set :deploy_to, "/home/#{fetch(:deploy_user)}/#{fetch(:application)}"

set :nvm_type, :user # or :system, depends on your nvm setup
set :nvm_node, 'v10.15.1'
set :nvm_map_bins, %w{node npm yarn}

set :scm_username, "unepwcmc-read"


set :rvm_type, :user
set :rvm_ruby_version, '2.6.3'

set :ssh_options, {
  forward_agent: true,
}

set :linked_files, %w{config/database.yml .env}

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/.well-known', 'storage')

set :keep_releases, 5

set :passenger_restart_with_touch, false

namespace :deploy do
  after :publishing, 'service:pp_default:restart'
  after :publishing, 'service:pp_import:restart'
end
