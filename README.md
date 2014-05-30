# DivAnn

### A database divergence analysis app

Ruby/Sinatra/SQLite

Divergence analysis of SQL Server databases/tables across multiple servers.

#### rowcounts2.rb

Runs webrick hosting Sinatra app.

#### analyze2.rb

Grab counts from a server. 

Opts: 

- --server - target server from databases.yml
- --initdb - drop and recreate database tables from DataMapper schema defs in /models
- --debug - verbose reporting

#### required gems

-- active_record - db orm for SQL Server (only one that doesn't require extra work to get adapter online)
-- data_mapper - db orm (simple SQLite interfacing)
-- trollop - opts parsing
-- haml - for views