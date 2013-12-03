do (require "source-map-support").install

nconf = require "nconf"
path  = require "path"
async = require "async"

mssql = require "mssql"

nconf.file path.resolve __dirname, "../../config.json"
config = nconf.get "sawa"

mssql.connect config
console.log "Connected"

sql = """
  Select top 10
    sprawa.ident,
    sprawa.rok,
    sprawa.numer,
    repertorium.symbol
  from
    sprawa
    inner join repertorium on sprawa.repertorium = repertorium.numer
  where
    repertorium.symbol = 'AmC'
  order by
    sprawa.ident desc
"""

async.waterfall [
  # Establish connection
  (done) ->
    request = new mssql.Request
    request.query sql, (error, suits) ->
      if error then return done error
     
      map = 
        (suit, done) ->
          sql = """
            Select
              ident,
              opis
            from 
              roszczenie
            where 
              id_sprawy = #{suit.ident}
              and typ_kwoty = 4
          """
          
          claims_request = new mssql.Request

          claims_request.query sql, (error, claims) ->
            if error then return done error
            console.dir claims
            suit.claims = claims
            done null, suit

      async.map suits, map, (error, suits) ->
        done error, suits
      
], (error, suits) ->
  if error then throw error
  console.dir suits
  do mssql.close