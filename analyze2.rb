#! ruby
require 'active_record'
require 'data_mapper'
require 'yaml'
require 'trollop'

opts = Trollop::options do
  opt :server, 'target server name', :type => :string
  opt :table, 'target table (optional)', :type => :string
  opt :initdb, 'drop/create tables'
  opt :debug, 'debug output' 
end

init_db = opts[:initdb]
debug = opts[:debug]

$dbconfig = YAML::load(File.open('databases.yml')) 

if debug
  DataMapper::Logger.new($stdout, :debug)
end

load 'models/model_dm.rb'

if init_db
  puts 'initializing database...'
  DataMapper.auto_migrate!
  puts 'done'
  exit
end

$db = opts[:server]
if $db.nil? 
  puts 'no target server, select server from databases.yml'
  exit
end

puts "storing counts for #{$db}"

class DISDB < ActiveRecord::Base
  self.abstract_class = true
  establish_connection $dbconfig[$db]
end

databases = DISDB.connection.select_values("select name from sysdatabases with (NOLOCK) where name not like '%_change' and name not like '%_update' and sid != 0x01 order by name")


server = Server.first_or_create( {:name => $db}, {:ip => $dbconfig[$db]['host']} )

databases.each do |db|
  tables = DISDB.connection.select_values("select name from #{db}.sys.Tables with (NOLOCK) where name not like '%_changes' and schema_id = 1 order by name");
  tables.each do |name|
    print "#{db}.dbo.#{name} = "
    STDOUT.flush 
    rowcount = DISDB.connection.select_value("select count_big(1) from #{db}.dbo.#{name} with (NOLOCK)")
    table = Table.first_or_create({:name => name.downcase}, {:enabled => true})
    ServerTable.first_or_create(:table => table, :server => server)
    Count.create(:count => rowcount, :timestamp => Time.now, :table => table, :server => server)
    puts rowcount
  end
end

DISDB.connection.disconnect!




