
# RowCounts

class Server < ActiveRecord::Base
  has_many :counts
  has_many :tables, :through => :servertables 
end

class Table < ActiveRecord::Base
  has_many :counts
  has_many :servers, :through => :servertables
end

class ServerTable < ActiveRecord::Base
  belongs_to :server
  belongs_to :table
end

class Run < ActiveRecord::Base
  has_many :counts
end

class Count < ActiveRecord::Base
  belongs_to :table
  belongs_to :count
  belongs_to :server
end