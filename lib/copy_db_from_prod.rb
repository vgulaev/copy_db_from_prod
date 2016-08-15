require 'net/ssh'
require 'yaml'

class CopyDbFromProd
  attr_accessor :cf

  def self.hi
    puts "Hello world!"
  end

  def load_conf(args)
    @cf = { host: args.host, user: args.user,
            keys: [File.open("#{ENV['HOME']}/.ssh/id_rsa", 'r').read],
            deploy_to: '/projects/insales3' }
  end

  def initialize(args)
    load_conf(args)
  end

  def download_schema
    Net::SSH.start(cf[:host], cf[:user], key_data: cf[:keys], keys_only: TRUE) do |ssh|
      @prod_conf = YAML.load(ssh.exec!("cat #{cf[:deploy_to]}/config/database.yml"))['production']
      return Zlib::GzipReader.new(StringIO.new(ssh.exec!(dump_schema))).read
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
end