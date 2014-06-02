#! ruby
require 'sinatra'
require 'data_mapper'
require 'haml'
require 'sinatra/reloader'
require 'json'

debug = true

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

  haml :tables
end

get '/tables/:server_id' do
  server_id = params[:server_id]
  @server = Server.get server_id
  
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

get '/counts' do
  @servers = Server.all(:order => :name)
  @last = `rubyw analyze2.rb --last --server tt8`
  haml :counts
end


post '/counts' do
  @servers = Server.all(:order => :name, :name.not => 'tt8')
  @server = Server.get params[:server]
  @last = `rubyw analyze2.rb --last --server tt8`
  query = "
    select t.name, c1.count as rc1, c2.count as rc2, (c1.count - c2.count) as diff, c1.table_id as tabid, c1.timestamp as t1, c2.timestamp as t2
    from counts c1 
    join counts c2 
    on c1.table_id = c2.table_id
    and c1.server_id = #{@server.id}
    and c2.server_id = (select id from servers where name = 'tt8')
    and c1.timestamp = (select max(timestamp) from counts where table_id = c1.table_id and server_id = c1.server_id)
    and c2.timestamp = (select max(timestamp) from counts where table_id = c2.table_id and server_id = c2.server_id)
    join tables t
    on c1.table_id = t.id
    and t.enabled = 't'
    order by t.name
  "
   
  @counts = repository(:default).adapter.select(query);
  
  haml :counts
end

post '/counts_json' do
  
  tt8 = Server.first(:name => 'tt8')
  server = Server.get params[:server2]
  table = Table.get params[:table_id]
  
  system("rubyw analyze2.rb --server #{tt8.name} --table #{table.id}")
  system("rubyw analyze2.rb --server #{server.name} --table #{table.id}")
  
  query = "
    select c1.count as rc1, c2.count as rc2, (c1.count - c2.count) as diff
    from counts c1 
    join counts c2 
    on c1.table_id = c2.table_id
    and c1.table_id = #{table.id}
    and c1.server_id = #{tt8.id}
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

get '/servers' do 
  @servers = Server.all(:order => :name)
  haml :servers
end

get '/feeds' do
  @feeds = Feed.all(:order => :name)
  haml :feeds 
end

post '/feeds' do

  feed = Feed.get params[:feed_id]
  if feed.enabled
    feed.update(:enabled => false)
  else
    feed.update(:enabled => true)
  end

end

