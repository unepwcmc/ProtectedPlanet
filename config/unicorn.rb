# Set the working application directory
working_directory "/var/www/pp/current"

# Unicorn PID file location
pid "/var/www/pp/current/tmp/pids/unicorn.pid"

# Path to logs
stderr_path "/var/www/pp/current/log/unicorn.log"
stdout_path "/var/www/pp/current/log/unicorn.log"

# Unicorn socket
listen "/tmp/unicorn.pp.sock"

# Number of processes
worker_processes 2

# Time-out
timeout 30
