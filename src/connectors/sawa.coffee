if not module.parent then do (require "source-map-support").install

debug   = require "debug"


async   = require "async"
_       = require "lodash"



mssql   = require "mssql"

Lawsuit = require "../models/Lawsuit"
Subject = require "../models/Subject"

$       = debug "SyncService:Connector:Sawa"


class SawaConnector
  constructor: (config, done) ->
    # TODO: @connection = new mssql.Connection ...
    # Have to deal with async anture of conne
    $ "Connecting to %s", config.server
    mssql.connect _.pick config, [
      "user"
      "password"
      "server"
      "database"
    ]
    $ "Connected."

  close: (done) ->
    do mssql.close
    $ "Good bye!"
    process.nextTick done

  syncSubjects: require "./syncSubjects"

  syncLawsuits: (options, done) -> # require "./syncLawsuits"
    if not done and typeof options is "function"
      done    = options
      options = {}

    
    # Create Lawsuit documents
    # TODO: first check if we already have them
    (rows, done) ->
      $ "%d lawsuits found", rows.length
      async.map rows,
        (row, done) ->
          done null, new Lawsuit
            repository: row.symbol.trim()
            year      : row.rok
            number    : row.numer
            file_date : row.d_wplywu
            _sync     :
              sawa      :
                last      : new Date
                ident     : row.ident
        done

    # WHAT A MESS :P
    # In 20 minutes they will the turn the power off in the office for UPS maintenence so I have to commit whatever works and go. SQL Server is down already anyway, so not much can be done.

    # Get rows from roszczenie
    # (lawsuits, done) ->
    #   async.map lawsuits,
    #     (lawsuit, done) ->
    #       sql = """
    #         Select
    #           ident,
    #           opis
    #         from 
    #           roszczenie
    #         where 
    #           id_sprawy = #{lawsuit._sync.sawa.ident}
    #           and typ_kwoty = 4
    #       """
    #       request = new mssql.Request # TODO: what happens to request once they are queried and go out of scope? Do they leak?
    #       request.query sql, (error, rows) ->
    #         # $ "Claims for lawsuit %s are %j", lawsuit.repository + " " + lawsuit.number + " / " + lawsuit.year, rows
    #         if error then return done error
    #         rows.forEach (row) -> lawsuit.claims.push
    #           type  : "Uznanie postanowienia wzorca umowy za niedozwolone"
    #           value : row.opis.trim()
    #         done null, lawsuit
    #     done
    
    # Map patries and their attorneys to case.
    # That's a bit tricky part. We have to use mapSeries, to make sure newly discovered subjects get saved before they are encountered for a second time.
    # (lawsuits, done) ->
    #   async.mapSeries lawsuits,
    #     (lawsuit, done) ->
    #       async.waterfall [
            
    #         # TODO: Parties are subjects + roles.
    #         # Let's find they attorneys in this lawsuit
    #         # (parties, done) ->

    #         # Expose this party's role:
    #         # TODO: expose his attorney as well!
    #         (party, done) ->
    #           $ "Saved %j", party
    #           console.dir {party, done}
    #           done null,
    #             subject : party._id
    #             role    : row.status.trim()
    #       ], (error, party) ->
    #         $ "Here?"
    #         console.dir {error, party, done}
    #         done error, party
    #         $ "Alive!"



    #         # Make lawsuit - subject reference in lawsuit.parties
    #         (parties, done) ->
    #           $ "Setting parties for lawsuit %s", lawsuit.reference_sign
    #           lawsuit.parties = parties
    #           done null, lawsuit

    #         # In development only: populate
    #         (lawsuit, done) ->
    #           lawsuit.populate "parties.subject", done

    #       ], done # Done waterfall lawsuit
    #     done      # Done map lawsuits
    

    # For each row of strona
    #   Find or create and store Subject document
    #   Get rows from broni + obronca
    #   For each row of obronca
    #     Find or create 

  # ], (error, lawsuits) ->
  #   if error then throw error
  #   async.map lawsuits,
  #     (lawsuit, done) ->
  #       console.log lawsuit.reference_sign
  #       console.log "Parties (#{lawsuit.parties.length}):"
  #       lawsuit.parties.forEach (party) -> console.log "\t#{party.subject.name.full}\t(#{party.role})"
  #       console.log "Claims (#{lawsuit.claims.length}):"
  #       lawsuit.claims.forEach (claim) -> console.log "\t#{claim.value}"
  #       console.log "\n"

  #       lawsuit.save done
  #     (error, lawsuits) ->
  #       if error then throw error
  #       $ "All done :)"
  #       do mssql.close
  #       do mongoose.connection.close


  # TODO: just import!

  # class SawaConnector
  #   list: (Model, done) ->
  #     $ "The list switch"
  #     switch Model.modelName 
  #       when "Lawsuit"
  #         async.waterfall [
  #           # Get lawsuits from Sawa DB
  #           (done) ->
  #             $ "Getting list of lawsuits"

  #           # Get claims
  #           (lawsuits, done) ->
  #             $ "Populating with claims"
  #             map = (lawsuit, done) ->
                  
  #               request = new mssql.Request

  #               request.query sql, (error, claims) ->
  #                 if error then return done error
  #                 lawsuit.claims = claims
  #                 done null, lawsuit

  #             async.map lawsuits, map, done

  #           # Get parties
  #           (lawsuits, done) ->
  #             $ "Populating with parties"
  #             map = (lawsuit, done) ->
  #               # TODO: only find ident, role and attorney ident
  #               # Population should be done by application logic
                  
  #               request = new mssql.Request

  #               request.query sql, (error, parties) ->
  #                 if error then return done error
  #                 lawsuit.parties = parties
  #                 done null, lawsuit

  #             async.map lawsuits, map, done

                
  #         ], done(error, lawsuits) ->
  #           if error then return done error
  #           done null, lawsuits 
  #           # .map (lawsuit) ->
  #           #  return
  #           #    repository: lawsuit.



# Are we standing alone?
if not module.parent
  $ "Initializing CLI for SawaConnector"

  path    = require "path"
  nconf   = require "nconf"
  nconf.file path.resolve __dirname, "../../config.json"
  config  = nconf.get "sawa"
  mongoose = require "mongoose"

  mongoose.connect "mongodb://localhost/test"

  connector = new SawaConnector config
  async.series [
    (done) -> async.parallel
      subjects: (done) -> Subject.remove done
      lawsuits: (done) -> Lawsuit.remove done
      done

    # Sync subjects
    (done) -> connector.syncSubjects done
    (done) -> connector.syncLawsuits limit: 10, done
    
    connector.close
  ], (error) ->
    if error then throw error
    do mongoose.connection.close
