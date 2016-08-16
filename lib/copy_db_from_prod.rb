require 'net/ssh'
require 'yaml'
require 'pg'

class CopyDbFromProd
  attr_accessor :cf, :conn

  def self.hi
    puts "Hello world!"
  end

  def load_conf(args)
    @cf = { host: args.host, user: args.user,
            keys: [File.open("#{ENV['HOME']}/.ssh/id_rsa", 'r').read],
            deploy_to: args.path }
  end

  def initialize(args)
    load_conf(args)
  end

  def download_schema
    Net::SSH.start(cf[:host], cf[:user], key_data: cf[:keys], keys_only: TRUE) do |ssh|
      yml_text = ssh.exec!("cat #{cf[:deploy_to]}/config/database.yml")
      begin
        @prod_conf ||= YAML.load(yml_text)['production']
      rescue => e
        raise "Can't access to database.yml, check -p params\n #{e}"
      end
      prod_data = ssh.exec!(dump_schema)
      if prod_data.include?('pg_dump') || prod_data.include?('warn')
        raise "error: pg_dump dosen't work correct\n #{prod_data}"
      else
        begin
          return Zlib::GzipReader.new(StringIO.new(prod_data)).read
        rescue => e
          raise "#{e}\n #{prod_data}"
        end
      end
    end
  end

  def dump_schema
    cmd = []
    { password: 'export PGPASSWORD=#{val} &&', database: 'pg_dump #{val}', host: '-h #{val}', port: '-p #{val}',
      username: '-U #{val}' }.each_pair do |key, val|
      cmd.push(val.sub('#{val}', @prod_conf[key.to_s].to_s)) if @prod_conf.key?(key.to_s)
    end
    "#{cmd.join(' ')} --schema-only --no-owner --no-privileges -Z9"
  end

  def drop_restore_table
    conn.exec("SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                AND table_name LIKE '%_201%'
                ORDER BY table_name"
    ) do |result|
      conn.exec(result.map { |row| "DROP TABLE #{row['table_name']}" }.join(';'))
    end
  end

  def load_schema
    @dev_conf = YAML.load(File.open('config/database.yml', 'r').read)['development']
    @conn = PGconn.open(host: @dev_conf['host'],
                     dbname: 'postgres',
                       user: @dev_conf['username'],
                   password: @dev_conf['password'])
    conn.exec("DROP DATABASE IF EXISTS #{@dev_conf['database']}")
    conn.exec("CREATE DATABASE #{@dev_conf['database']}")
    @conn = PGconn.open(host: @dev_conf['host'],
                     dbname: @dev_conf['database'],
                       user: @dev_conf['username'],
                   password: @dev_conf['password'])
    schema = download_schema
    begin
      conn.exec(schema)
    rescue => e
      raise "Database #{@dev_conf['database']}\n#{e}\n #{schema}"
    end
    drop_restore_table if 'insales_dev' == @dev_conf['database']
  end

  def copy_env_table

  end
end