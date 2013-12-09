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

  syncLawsuits: (options, done) -> # require "./syncLawsuits"
    if not done and typeof options is "function"
      done    = options
      options = {}

    async.waterfall [
      (done) -> # Get rows from sprawa + repertorium
        $ "Looking for lawsuits"
        sprawa = new Statement """
          Select :limit
            sprawa.ident,
            repertorium.symbol as repertorium,
            sprawa.rok,
            sprawa.numer,
            sprawa.d_wplywu
          from
            sprawa
            inner join repertorium on sprawa.repertorium = repertorium.numer
          where
            sprawa.czyus = 0
            :ident
            :repertorium
          order by
            sprawa.ident desc
          """,
          limit       : (value) -> if typeof value is "number" and value then "top #{value}" else ""
          ident       : Statement.helpers.where "sprawa.ident",       Number
          repertorium : Statement.helpers.where "repertorium.symbol", String

        $ sprawa.bind options
        sprawa.exec options, done
      (rows, done) -> # Create Lawsuit documents
        $ "There are %d lawsuits here.", rows.length
        async.mapSeries rows, # Do we really need that? eachSeries would be less memory hungry probabily.
          (row, done) ->
            async.waterfall [
              (done) -> Lawsuit.findOne "_sync.sawa.ident": row.ident, done
              (lawsuit, done) ->
                $ "Lawsuit is %j", lawsuit
                
                if lawsuit 
                  $ "We already know this lawsuit. It's %s. Skipping to next.", lawsuit.reference_sign
                  return done (Error "Already synced"), lawsuit # TODO: compare and sync
                                                                # Error will be nullified down the drain
                else
                  $ "That's a new lawsuit. It's filed as %s", "#{row.repertorium} #{row.numer} / #{row.rok}"
                  done null, new Lawsuit
                    repository: row.repertorium.trim()
                    year      : row.rok
                    number    : row.numer
                    file_date : row.d_wplywu
                    _sync     :
                      sawa      :
                        last      : new Date
                        ident     : row.ident

              # Get rows from roszczenie and store in lawsuit document
              (lawsuit, done) ->
                async.waterfall [
                  (done) ->
                    roszczenie = new Statement """
                      Select
                        ident,
                        opis
                      from 
                        roszczenie
                      where 
                        typ_kwoty = 4
                        :id_sprawy                        
                      """,
                      id_sprawy: Statement.helpers.where "id_sprawy", Number

                    roszczenie.exec id_sprawy: lawsuit._sync.sawa.ident, done
                  (rows, done) ->
                    $ "Claims for lawsuit %s are %j", lawsuit.reference_sign, rows
                    rows.forEach (row) -> lawsuit.claims.push
                      type  : "Uznanie postanowienia wzorca umowy za niedozwolone"
                      value : row.opis.trim()
                    done null, lawsuit

                ], done

              # Get rows from strona + status
              (lawsuit, done) ->
                async.waterfall [
                  (done) ->
                    strona = new Statement """
                      Select
                        dane_strony.ident,
                        status.nazwa as status
                      from 
                        strona
                        inner join status on strona.id_statusu = status.ident
                        inner join dane_strony on strona.id_danych = dane_strony.ident
                      where 
                        strona.czyus = 0
                        :id_sprawy                        
                      """,
                      id_sprawy: Statement.helpers.where "strona.id_sprawy", Number

                    strona.exec id_sprawy: lawsuit._sync.sawa.ident, done
                  (rows, done) ->
                    $ "There are %d party people in this suit. Put on your suit and dance!", rows.length
                    # TODO: sync selected subjects, and then ...
                    # Find subject document
                    async.each rows,
                      (row, done) ->
                        async.parallel
                          subject : (done) ->
                            Subject.findOne "_sync.sawa.dane_strony_ident": row.ident, (error, subject) ->
                              $ "Subject is %j", subject
                              done error, subject
                          role    : (done) -> done null, row.status.trim()
                          (error, party) ->
                            if error then return done error
                            lawsuit.parties.push party
                            done null
                      (error) -> done error, lawsuit
                ], done

              # Get rows from broni
            ], (error, lawsuit) ->
              if error? and error.message is "Already synced" then error = null
              if error then return done error
              lawsuit.save (error) -> done error, lawsuit

          done
    ], (error, lawsuits) ->
      if error then throw error
      done null, lawsuits.length 

        
  
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
      lawsuits: (done) -> Lawsuit.remove done
      done

    # Sync subjects
    (done) -> connector.syncSubjects ident: [1,2,3,4], limit: 5, done
    (done) -> connector.syncLawsuits limit: 10, repertorium: "AmC", done
    
    connector.close
  ], (error) ->
    if error then throw error
    do mongoose.connection.close
