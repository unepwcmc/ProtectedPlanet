module ActiveStorageTransfer
  def self.transfer only_dump=false
    config = ActiveRecord::Base.connection_config

    backup_path = Rails.root.join("tmp/active_storage.dump")

    dump_command = []
    dump_command << "PGPASSWORD=#{config[:password]}" if config[:password].present?
    dump_command << "pg_dump"
    dump_command << "-d #{config[:database]}_backup"
    dump_command << "-t 'active_storage_*'"
    dump_command << "-U #{config[:username]}"
    dump_command << "-h #{config[:host]}"
    dump_command << "> #{backup_path.to_s}"
    system(dump_command.join(" "))

    return true if only_dump

    restore_command = []
    restore_command << "PGPASSWORD=#{config[:password]}" if config[:password].present?
    restore_command << "psql"
    restore_command << "-d #{config[:database]}"
    restore_command << "-U #{config[:username]}"
    restore_command << "-h #{config[:host]}"
    restore_command << "< #{backup_path.to_s}"
    system(restore_command.join(" "))
  end
end