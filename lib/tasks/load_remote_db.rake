# rubocop:disable all
require 'yaml'
require 'json'
require 'shellwords'

namespace :load_remote_db do
  task :run do |t, _|
    args = ARGV
    RemoteDbLoader.new.call(args)
  end
end

class RemoteDbLoader
  def call(args)
    env = 'staging'
    env = args[1] if args.count > 1

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

    puts 'Downloading remote backup file...'
    download_db_dump_command =
      %(scp #{@server_user}@#{@server_ip}:#{shared_path}/backup.sql .)

    `#{download_db_dump_command}`

    puts 'Deleting remote backup file...'
    delete_db_dump_command = %(ssh #{@server_user}@#{@server_ip} \
    "rm -rf #{shared_path}/backup.sql")

    if password == nil
      import_db_cmd =
        %(mysql -u #{username} #{database} < backup.sql)
    else
      import_db_cmd =
        %(mysql -u #{username} -p'#{password}' #{database} < backup.sql)
    end

    puts 'Importing database into local environment...'
    `#{import_db_cmd}`

    puts 'Cleaning up...'
    `rm backup.sql`
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
