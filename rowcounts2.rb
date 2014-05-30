#! ruby
require 'sinatra'
require 'data_mapper'
require 'haml'
require 'sinatra/reloader'

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
  
  haml :counts
end


post '/counts' do
  @servers = Server.all(:order => :name)
  
  @server1 = Server.get params[:server1]
  @server2 = Server.get params[:server2]
  
  query = "
   select t.name, c1.count as rc1, c2.count as rc2, abs(c1.count - c2.count) as diff, c1.table_id as tabid
   from counts c1 
   join counts c2 
   on c1.table_id = c2.table_id
   and c1.server_id = #{@server1.id}
   and c2.server_id = #{@server2.id}
   and c1.timestamp = (select max(timestamp) from counts where table_id = c1.table_id and server_id = c1.server_id)
   and c2.timestamp = (select max(timestamp) from counts where table_id = c2.table_id and server_id = c2.server_id)
   join tables t
   on c1.table_id = t.id
   order by t.name
 "
   
  @counts = repository(:default).adapter.select(query);
  
  haml :counts
end

get '/servers' do 
  @servers = Server.all
  haml :servers
end
