#! ruby

DataMapper::setup(:default, "sqlite://#{Dir.pwd}/rowcounts.db")

class Server
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String
  property :ip,   String

  has n, :tables, :through => :serverTables
  
  has n, :counts
  
end


class Table
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  property :enabled, Boolean

  has n, :servers, :through => :serverTables
  
  has n, :counts

end

class Count
  include DataMapper::Resource
  
  property :id,   Serial
  property :count, Float
  property :timestamp, DateTime

  belongs_to :server
  belongs_to :table
  
end

class ServerTable
  include DataMapper::Resource
  
  property :id, Serial
  
  belongs_to :server
  belongs_to :table
end

DataMapper.finalize