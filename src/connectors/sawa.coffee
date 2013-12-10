if not module.parent then do (require "source-map-support").install

debug     = require "debug"


async     = require "async"
_         = require "lodash"

mssql     = require "mssql"
Statement = require "./SQLStatement"

Lawsuit   = require "../models/Lawsuit"
Subject   = require "../models/Subject"



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
  syncLawsuits: require "./syncLawsuits"


        
  
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
      # subjects: (done) -> Subject.remove done
      lawsuits: (done) ->
        $ "Clearing lawsuits data"
        Lawsuit.remove done
      done

    # Sync subjects
    # (done) -> connector.syncSubjects ident: [1,2,3,4], limit: 5, done
    (done) ->
      $ "Synhcronizing lawsuits data"
      connector.syncLawsuits ident: [1, 300, 3432, 43243, 434, 443], done
    
    connector.close
  ], (error) ->
    if error then throw error
    do mongoose.connection.close
