namespace :config do
  task :setup do
   ask(:db_user, 'db_user')
   ask(:db_pass, 'db_pass')
   ask(:db_name, 'db_name')
   ask(:db_host, 'db_host')
setup_config = <<-EOF
#{fetch(:rails_env)}:
adapter: postgresql
database: #{fetch(:db_name)}
username: #{fetch(:db_user)}
password: #{fetch(:db_pass)}
host: #{fetch(:db_host)}
EOF
  on roles(:web) do
     execute "mkdir -p #{shared_path}/config"
     upload! StringIO.new(setup_config), "#{shared_path}/config/database.yml"
    end
  end
end


namespace :config do
   task:setup do
on roles(:db) do
execute "sudo -u postgres createdb #{fetch(:application)}-#{fetch(:rails_env)}"
execute "sudo -u postgres psql -c 'CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology;' #{fetch(:application)}-#{fetch(:rails_env)}"
 end
 end
end





namespace :config do
task :setup do
vhost_config = <<-EOF
server {
   listen 80;
   server_name #{fetch(:application)}.#{fetch(:server)};
   passenger_enabled on;
   root #{deploy_to}/current/public;
   rails_env #{fetch(:rails_env)};
   client_max_body_size 20M;
   passenger_ruby /home/#{fetch(:deploy_user)}/.rvm/gems/ruby-#{fetch(:rvm_ruby_version)}/wrappers/ruby;
   gzip on;
   location ~ ^/assets/ {
   root #{deploy_to}/current/public;
   expires max;
   add_header Cache-Control public;
   add_header ETag "";
   break;
 }
error_page 503 @503;
# Return a 503 error if the maintenance page exists.
if (-f #{deploy_to}shared/public/system/maintenance.html) {
  return 503;
}
location @503 {
  # Serve static assets if found.
  if (-f $request_filename) {
    break;
  }
  # Set root to the shared directory.
  root #{deploy_to}/shared/public;
  rewrite ^(.*)$ /system/maintenance.html break;
}
  
  
}
EOF

  on roles(:app) do
     execute "sudo mkdir -p /etc/nginx/sites-available"
     upload! StringIO.new(vhost_config), "/tmp/vhost_config"
     execute "sudo mv /tmp/vhost_config /etc/nginx/sites-available/#{fetch(:application)}"
     execute "sudo ln -s /etc/nginx/sites-available/#{fetch(:application)} /etc/nginx/sites-enabled/#{fetch(:application)}"
    end
  end
end

