#! ruby
require 'sinatra'
require 'data_mapper'
require 'haml'
require 'sinatra/reloader'
require 'json'
require 'logger'

debug = false

set :server, 'thin'

gold_server = 'tt8'

logger = Logger.new('log.txt', 'daily')

if debug
  DataMapper::Logger.new($stdout, :debug)
end

load 'models/model_dm.rb'

get '/' do
  @home = true
  haml :index
end

get '/tables' do
  @tables = Table.all(:order => :name)
  @feeds = Feed.all(:order => :name)
  haml :tables
end

get '/tables/:server_id' do
  server_id = params[:server_id]
  
  @server = Server.get server_id
  @feeds = Feed.all(:order => :name)
  @tables = @server.tables.all(:order => :name)

  haml :tables
end

post '/tables' do
  table = Table.get params[:table_id]
  if table.enabled
    table.update(:enabled => false)
  else
    table.update(:enabled => true)
  end
end

post '/get_tables' do
  feed = Feed.get params[:feed]
  @tables = Table.all(:order => :name, :feed => feed)
  @feeds = Feed.all(:order => :name)
  
  haml :tables_partial, :layout => false
end


get '/counts' do
  @gold_server = gold_server
  @servers = Server.all(:order => :name, :name.not => @gold_server)
  @feeds = Feed.all(:order => :name, :enabled => true, :server => @servers[0])
  @last = `rubyw analyze2.rb --last --server #{@gold_server}`
  haml :counts
end


post '/counts' do
  @gold_server = gold_server
  @servers = Server.all(:order => :name, :name.not => @gold_server)
  @server = Server.get params[:server]
  @feed = Feed.get params[:feed]
  @feeds = Feed.all(:order => :name, :enabled => true, :server => @server)
  
  @last = `rubyw analyze2.rb --last --server #{@gold_server}`
  
  # system("rubyw analyze2.rb --server #{@server.name} --feed #{@feed.id}")
  # system("rubyw analyze2.rb --server #{@gold_server} --feed #{@feed.id}")
   
  query = "
    select t.name, c1.count as rc1, c2.count as rc2, (c1.count - c2.count) as diff, c1.table_id as tabid, c1.timestamp as t1, c2.timestamp as t2
    from counts c1 
    join counts c2 
    on c1.table_id = c2.table_id
    and c1.server_id = (select id from servers where name = '#{@gold_server}')
    and c2.server_id = #{@server.id}
    and c1.timestamp = (select max(timestamp) from counts where table_id = c1.table_id and server_id = c1.server_id)
    and c2.timestamp = (select max(timestamp) from counts where table_id = c2.table_id and server_id = c2.server_id)
    join tables t
    on c1.table_id = t.id
    and t.enabled = 't'
    and t.feed_id = #{@feed.id}
    order by t.name
  "
   
  @counts = repository(:default).adapter.select(query);
  
  haml :counts
end

post '/counts_json' do
  @gold_server = gold_server
  gold = Server.first(:name => @gold_server)
  server = Server.get params[:server]
  table = Table.get params[:table_id]
  
  logger.info('counts_json') {"server: #{server.name} table: #{table.name}"}
  
  system("rubyw analyze2.rb --server #{gold.name} --table #{table.id}")
  system("rubyw analyze2.rb --server #{server.name} --table #{table.id}")
  
  query = "
    select c1.count as rc1, c2.count as rc2, (c1.count - c2.count) as diff
    from counts c1 
    join counts c2 
    on c1.table_id = c2.table_id
    and c1.table_id = #{table.id}
    and c1.server_id = #{gold.id}
    and c2.server_id = #{server.id}
    and c1.timestamp = (select max(timestamp) from counts where table_id = c1.table_id and server_id = c1.server_id)
    and c2.timestamp = (select max(timestamp) from counts where table_id = c2.table_id and server_id = c2.server_id)
  "
   
  counts = repository(:default).adapter.select(query)[0];
  
  
  counts.rc1 = counts.rc1.round
  counts.rc2 = counts.rc2.round
  counts.diff = counts.diff.round
  
  Hash[counts.each_pair.to_a].to_json
  
end

post '/counts_json2' do
  
  @gold_server = gold_server
  @servers = Server.all(:order => :name, :name.not => @gold_server)
  @server = Server.get params[:server_id]
  @feed = Feed.get params[:feed_id]
  @feeds = Feed.all(:order => :name, :enabled => true)
  
  logger.info('counts_json2') {"server: #{@server.name} feed: #{@feed.name}"}
  
  puts "running counts for server: #{@server.name} feed: #{@feed.name}"
    
  system("rubyw analyze2.rb --server #{@server.name} --feed #{@feed.id}")
  puts "done with #{@server.name}"
  system("rubyw analyze2.rb --server #{@gold_server} --feed #{@feed.id}")
  puts "done with #{@gold_server}"
   
  query = "
    select t.name, c1.count as rc1, c2.count as rc2, (c1.count - c2.count) as diff, c1.table_id as tabid, c1.timestamp as t1, c2.timestamp as t2
    from counts c1 
    join counts c2 
    on c1.table_id = c2.table_id
    and c1.server_id = (select id from servers where name = '#{@gold_server}')
    and c2.server_id = #{@server.id}
    and c1.timestamp = (select max(timestamp) from counts where table_id = c1.table_id and server_id = c1.server_id)
    and c2.timestamp = (select max(timestamp) from counts where table_id = c2.table_id and server_id = c2.server_id)
    join tables t
    on c1.table_id = t.id
    and t.enabled = 't'
    and t.feed_id = #{@feed.id}
    order by t.name
  "
  
  
  @counts = repository(:default).adapter.select(query)
  
  haml :counts_partial, :layout => false
end

post '/get_feeds' do
  server = Server.get params[:server_id]
  
  @feeds = Feed.all(:order => :name, :enabled => true, :server => server)
  
  haml :feeds_partial, :layout => false
end

post '/get_feeds2' do
  server = Server.get params[:server_id]
  
  @feeds = Feed.all(:order => :name, :enabled => true, :server => server)
  
  haml :feeds_partial2, :layout => false
end


get '/servers' do 
  @servers = Server.all(:order => :name)
  haml :servers
end

get '/feeds' do
  @feeds = Feed.all(:order => :name)
  @servers = Server.all(:order => :name, :name.not => gold_server)
  haml :feeds 
end

post '/feeds' do
  @servers = Server.all(:order => :name)
  feed = Feed.get params[:feed_id]
  if feed.enabled
    feed.update(:enabled => false)
    feed.tables.update(:enabled => false)
  else
    feed.update(:enabled => true)
    feed.tables.update(:enabled => false)
  end

end

