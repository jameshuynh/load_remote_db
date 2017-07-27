# rubocop:disable all
require 'yaml'
require 'json'
require 'shellwords'

namespace :db do
  task :load_from_remote do |t, _|
    RemoteDbLoader.new.call
  end
end

class RemoteDbLoader
  def call
    env = 'staging'
    env = ENV['SERVER'] if ENV['SERVER'].present?

    to_be_rsync_folder = ENV['SYNC_FOLDER']

    database_yml =
      "#{Rails.root}/config/database.yml"
    development_db = YAML.load_file(database_yml)['development']

    username = development_db['username']
    password = development_db['password']
    database = development_db['database']

    eval File.read("#{Rails.root}/config/deploy/#{env}.rb")

    ## get remote database config.yml
    get_db_info_command = %{ssh #{@server_user}@#{@server_ip} \
    "/home/#{@server_user}/.rbenv/shims/ruby -e \
    \\"require 'yaml'; \
    puts YAML.load_file('#{@deploy_to}/shared/config/database.yml')['#{env}']\\""}

    shared_path = "#{@deploy_to}/shared"

    remote_db_config = eval `#{get_db_info_command}`
    remote_db_username = remote_db_config["username"]
    remote_db_password = remote_db_config["password"]
    remote_db_host = remote_db_config["host"]
    remote_db_name = remote_db_config["database"]

    ## run the real backup
    puts 'Running the remote backup...'
    mysql_cmd = "mysqldump -u #{remote_db_username} -p'#{remote_db_password}' \
    -h #{remote_db_host} #{remote_db_name} > #{shared_path}/backup.sql".shellescape
    backup_command = %(ssh #{@server_user}@#{@server_ip} #{mysql_cmd})
    system(backup_command)

    check_gzip_exist_cmd = 'which gzip'
    check_gzip_exist_remote_cmd =
      %(ssh #{@server_user}@#{@server_ip} #{check_gzip_exist_cmd})

    puts 'Checking for remote gzip location...'
    gzip_exist = system(check_gzip_exist_remote_cmd) != ''

    if gzip_exist
      puts 'zipping remote backup file...'
      zip_cmd = "gzip -f #{shared_path}/backup.sql"
      zip_cmd_remote =
        %(ssh #{@server_user}@#{@server_ip} #{zip_cmd})
      system(zip_cmd_remote)
    end

    puts 'Downloading remote backup file...'
    bk_extension = gzip_exist ? 'sql.gz' : 'sql'
    download_db_dump_command =
      %(scp #{@server_user}@#{@server_ip}:#{shared_path}/backup.#{bk_extension} .)

    system(download_db_dump_command)

    puts 'Deleting remote backup file...'
    delete_db_dump_command = %(ssh #{@server_user}@#{@server_ip} \
    "rm -rf #{shared_path}/backup.#{bk_extension}")

    system(delete_db_dump_command)

    if gzip_exist
      `gunzip -f backup.sql.gz`
    end

    if ENV['DOWNLOAD_ONLY']
      puts 'backup.sql file is now stored at your Rails root folder!'
      `open .`
    else
      if password == nil
        import_db_cmd =
          %(mysql -u #{username} #{database} < backup.sql)
      else
        import_db_cmd =
          %(mysql -u #{username} -p'#{password}' #{database} < backup.sql)
      end

      puts 'Importing database into local environment...'
      `#{import_db_cmd}`

      puts 'Cleaning up database backup...'
      `rm backup.sql`
    end

    if to_be_rsync_folder
      puts "Synchorinizing #{to_be_rsync_folder} folder..."
      `mkdir -p 'public/#{to_be_rsync_folder.gsub('public/', '')}'`
      sync_folder_cmd = %(rsync -r \
#{@server_user}@#{@server_ip}:#{shared_path}/#{to_be_rsync_folder} \
'public/#{to_be_rsync_folder.gsub('public/', '')}')
      puts sync_folder_cmd
      system(sync_folder_cmd)
    end

    puts 'DONE!'
  end

  def method_missing(name, *args, &block)
    return unless %I[server set].include?(name)
    @server_ip ||= if name == :server
                     args[0]
                   elsif name == :set && args[0] == :domain
                     args[1]
                   end
    @server_user ||= args[1] if name == :set && args[0] == :user
    @deploy_to ||= args[1] if name == :set && args[0] == :deploy_to
  end
end
