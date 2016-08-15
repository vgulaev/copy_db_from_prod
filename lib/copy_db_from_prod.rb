require 'net/ssh'
require 'yaml'
require 'pg'

class CopyDbFromProd
  attr_accessor :cf

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
      @prod_conf = YAML.load(ssh.exec!("cat #{cf[:deploy_to]}/config/database.yml"))['production']
      prod_data = ssh.exec!(dump_schema)
      if prod_data.include?('pg_dump') || prod_data.include?('warn')
        raise "error: pg_dump dosen't work correct \n #{prod_data}"
      else
        return Zlib::GzipReader.new(StringIO.new(ssh.exec!(prod_data))).read
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

  def load_schema
    @dev_conf = YAML.load(File.open('config/database.yml', 'r').read)['development']
    conn = PGconn.open(host: @dev_conf['host'],
                     dbname: 'postgres',
                       user: @dev_conf['username'],
                   password: @dev_conf['password'])
    conn.exec("DROP DATABASE IF EXISTS #{@dev_conf['database']}")
    conn.exec("CREATE DATABASE #{@dev_conf['database']}")
    conn = PGconn.open(host: @dev_conf['host'],
                     dbname: @dev_conf['database'],
                       user: @dev_conf['username'],
                   password: @dev_conf['password'])
    conn.exec(download_schema)
  end
end