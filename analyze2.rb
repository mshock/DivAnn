#! ruby
require 'active_record'
require 'data_mapper'
require 'yaml'
require 'trollop'

# handles all queries to production and batch reporting db updates

opts = Trollop::options do
  opt :server, 'target server name', :type => :string
  opt :table, 'target table_id (optional)', :type => :int
  opt :feed, 'target feed (optional)', :type => :int
  opt :last, 'get last update'
  opt :initdb, 'drop/create tables'
  opt :nocount, 'skip counts, initialize tables and feeds'
  opt :debug, 'debug output' 
end

$dbconfig = YAML::load(File.open('databases.yml')) 

if opts[:debug]
  DataMapper::Logger.new($stdout, :debug)
end

load 'models/model_dm.rb'

if opts[:initdb]
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



class DISDB < ActiveRecord::Base
  self.abstract_class = true
  establish_connection $dbconfig[$db]
end

if opts[:last]
  update = DISDB.connection.select_one('select value1, value2 from qai_master.dbo.mqasys')
  puts "#{update['value1'].strftime('%Y%m%d')}-#{update['value2']}"
  exit
end


databases = DISDB.connection.select_values("select name from sysdatabases with (NOLOCK) where name not like '%_change' and name not like '%_update' and sid != 0x01 order by name")

server = Server.first_or_create( {:name => $db}, {:ip => $dbconfig[$db]['host']} )

def create_count(server, dbname, tablename)
  print "#{dbname}.dbo.#{tablename} = "
  STDOUT.flush 
  rowcount = DISDB.connection.select_value("select count_big(1) from #{dbname}.dbo.#{tablename} with (NOLOCK)")
  feed = Feed.first_or_create({:name => dbname}, {:enabled => true}) 
  table = Table.first_or_create({:name => tablename.downcase}, {:enabled => true, :feed => feed})
  ServerTable.first_or_create(:table => table, :server => server)
  Count.create(:count => rowcount, :timestamp => Time.now, :table => table, :server => server)
  puts rowcount
end

def create_nocount(server, dbname, tablename)
  print "#{dbname}.dbo.#{tablename} = "
  STDOUT.flush
  feed = Feed.first_or_create({:name => dbname}, {:enabled => true}) 
  table = Table.first_or_create({:name => tablename.downcase}, {:enabled => true, :feed => feed})
  ServerTable.first_or_create(:table => table, :server => server)
  puts 'created'
end

unless opts[:feed].nil?
  feed = Feed.get opts[:feed]
  tables = feed.tables.all(:enabled => true, :order => :name)
  
  tables.each do |table|
    if server.name == 'tt8'
      print "qai_master.dbo.#{table.name} = "
      STDOUT.flush 
      rowcount = DISDB.connection.select_value("select count_big(1) from qai_master.dbo.#{table.name} with (NOLOCK)")
      feed = Feed.first_or_create({:name => feed.name}, {:enabled => true})
      table = Table.first_or_create({:name => table.name.downcase}, {:enabled => true, :feed => feed})
      ServerTable.first_or_create(:table => table, :server => server)
      Count.create(:count => rowcount, :timestamp => Time.now, :table => table, :server => server)
      puts rowcount
    else
      create_count(server, feed.name, table.name)
    end
  end
  exit
end

if opts[:nocount].nil? 
  unless opts[:table].nil?
    table = Table.get opts[:table]
    database = nil
    databases.each do |db|
      puts "checking #{db}"
      tables = DISDB.connection.select_values("select lower(name) from #{db}.sys.Tables with (NOLOCK) where name not like '%_changes' and schema_id = 1 order by name");
      if tables.include? table.name.downcase
        database = db
        break
      end
    end
    if database.nil?
      puts "table not found in databases on this server"
    else
      create_count(server, database, table.name)
    end
  else 
    puts "storing counts for #{$db}"
    databases.each do |db|
      tables = DISDB.connection.select_values("select name from #{db}.sys.Tables with (NOLOCK) where name not like '%_changes' and schema_id = 1 order by name");
      tables.each do |name|
        create_count(server, db, name)
      end
    end
  end
  else 
    databases.each do |db|
      tables = DISDB.connection.select_values("select lower(name) from #{db}.sys.Tables with (NOLOCK) where name not like '%_changes' and schema_id = 1 order by name")
      tables.each do |name|
        create_nocount(server, db, name)
      end
    end
end
DISDB.connection.disconnect!