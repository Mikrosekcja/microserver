do (require "source-map-support").install

debug   = require "debug"

path    = require "path"
async   = require "async"
_       = require "lodash"

nconf   = require "nconf"

mssql   = require "mssql"

Lawsuit = require "../models/Lawsuit"
Subject = require "../models/Subject"

$       = debug "SyncService:Connector:Sawa"

nconf.file path.resolve __dirname, "../../config.json"

config  = nconf.get "sawa"



# Connect to and clean DB
# TODO: remove :)
mongoose = require "mongoose"


class SawaConnector
  constructor: ->
    mssql   .connect config
    mongoose.connect "mongodb://localhost/test"
    $ "Connected."

  close: (done) ->
    do mssql.close
    do mongoose.connection.close
    $ "Good bye!"
    process.nextTick done
    

  # In development only
  cleanDB: (done) ->
    async.parallel
      subjects: (done) -> Subject.remove done
      lawsuits: (done) -> Lawsuit.remove done
      done

  syncSubjects: (options, done) ->
    if not done and typeof options is "function"
      done    = options
      options = {}

    async.waterfall [

      # Get rows from strona + status + dane strony
      (done) ->
        $ "Looking for people!"

        # TODO: DRY - make prepared statement functionality for mssql
        sanitize =
          limit: Number
          ident: Number

        params = _.pick options, _.keys sanitize
        $ "Params are", { params, sanitize }
        params = _.transform params, (params, value, name) ->
          $ "Sanitizing %s %s", name, value
          params[name] = sanitize[name] value
          

        
        
        sql = """
          Select #{if params.limit? then "top " + params.limit else ""}
            dane_strony.ident,
            dane_strony.imie,
            dane_strony.nazwisko,
            dane_strony.plec,
            dane_strony.fizpraw,
            dane_strony.pesel,
            dane_strony.nip,
            dane_strony.krs,
            dane_strony.regon
          from 
            dane_strony
          where 
            dane_strony.czyus = 0
            and dane_strony.nazwisko is not null
            #{if params.ident? then "and dane_strony.ident = " + params.ident else ""}
        """
        $ "SQL is %s", sql
        # TODO: if no first nor last name then rise an error and handle it down the drain

        request = new mssql.Request
        request.query sql, done

      # Find or create subject documents
      (rows, done) ->
        $ "There are %d party people.", rows.length
        async.mapSeries rows, # Do we really need that? eachSeries would be less memory hungry probabily.
          (row, done) ->
            async.waterfall [
              # TODO: first check if we already have them
              (done) -> Subject.findOne "_sync.sawa.dane_strony_ident": row.ident, done
              (subject, done) ->
                $ "Subject is %j", subject
                
                if subject 
                  $ "We know that guy! It's a %s", subject.name.full
                  # TODO: compare and sync
                  return done null, subject
                
                else 
                  subject = new Subject
                    name      :
                      first     : row.imie?.trim()
                      last      : row.nazwisko?.trim()
                    _sync     :
                      sawa      :
                        last              : new Date
                        dane_strony_ident : row.ident

                  $ "There's a new guy. Allow me to introduce %s", subject.name.full
                  subject.save (error) -> done error, subject
            ], done
          done
    ], (error, subjects) ->
      if error then throw error
      done null, subjects.length 

connector = new SawaConnector
async.series [
  # connector.cleanDB
  (done) -> connector.syncSubjects ident: 320, done
  connector.close
], (error) -> if error then throw error


  # Get lawsuits
  # ---------
  # syncLawsuits: (options, done) ->
  #   if not done and typeof options is "function"
  #     done    = options
  #     options = {}

  #   # Get rows from sprawa + repertorium
  #   (done) ->
  #     $ "Go!"
  #     sql     = """
  #       Select top 10
  #         sprawa.ident,
  #         repertorium.symbol,
  #         sprawa.rok,
  #         sprawa.numer,
  #         sprawa.d_wplywu
  #       from
  #         sprawa
  #         inner join repertorium on sprawa.repertorium = repertorium.numer
  #       where
  #         repertorium.symbol = 'AmC'
  #       order by
  #         sprawa.ident desc
  #     """
  #     request = new mssql.Request
  #     request.query sql, done
    
  #   # Create Lawsuit documents
  #   # TODO: first check if we already have them
  #   (rows, done) ->
  #     $ "%d lawsuits found", rows.length
  #     async.map rows,
  #       (row, done) ->
  #         done null, new Lawsuit
  #           repository: row.symbol.trim()
  #           year      : row.rok
  #           number    : row.numer
  #           file_date : row.d_wplywu
  #           _sync     :
  #             sawa      :
  #               last      : new Date
  #               ident     : row.ident
  #       done

  #   # Get rows from roszczenie
  #   (lawsuits, done) ->
  #     async.map lawsuits,
  #       (lawsuit, done) ->
  #         sql = """
  #           Select
  #             ident,
  #             opis
  #           from 
  #             roszczenie
  #           where 
  #             id_sprawy = #{lawsuit._sync.sawa.ident}
  #             and typ_kwoty = 4
  #         """
  #         request = new mssql.Request # TODO: what happens to request once they are queried and go out of scope? Do they leak?
  #         request.query sql, (error, rows) ->
  #           # $ "Claims for lawsuit %s are %j", lawsuit.repository + " " + lawsuit.number + " / " + lawsuit.year, rows
  #           if error then return done error
  #           rows.forEach (row) -> lawsuit.claims.push
  #             type  : "Uznanie postanowienia wzorca umowy za niedozwolone"
  #             value : row.opis.trim()
  #           done null, lawsuit
  #       done
    
  #   # Map patries and their attorneys to case.
  #   # That's a bit tricky part. We have to use mapSeries, to make sure newly discovered subjects get saved before they are encountered for a second time.
  #   # (lawsuits, done) ->
  #   #   async.mapSeries lawsuits,
  #   #     (lawsuit, done) ->
  #   #       async.waterfall [
            
  #   #         # TODO: Parties are subjects + roles.
  #   #         # Let's find they attorneys in this lawsuit
  #   #         # (parties, done) ->

  #   #         # Expose this party's role:
  #   #         # TODO: expose his attorney as well!
  #   #         (party, done) ->
  #   #           $ "Saved %j", party
  #   #           console.dir {party, done}
  #   #           done null,
  #   #             subject : party._id
  #   #             role    : row.status.trim()
  #   #       ], (error, party) ->
  #   #         $ "Here?"
  #   #         console.dir {error, party, done}
  #   #         done error, party
  #   #         $ "Alive!"



  #   #         # Make lawsuit - subject reference in lawsuit.parties
  #   #         (parties, done) ->
  #   #           $ "Setting parties for lawsuit %s", lawsuit.reference_sign
  #   #           lawsuit.parties = parties
  #   #           done null, lawsuit

  #   #         # In development only: populate
  #   #         (lawsuit, done) ->
  #   #           lawsuit.populate "parties.subject", done

  #   #       ], done # Done waterfall lawsuit
  #   #     done      # Done map lawsuits
    

  #   # For each row of strona
  #   #   Find or create and store Subject document
  #   #   Get rows from broni + obronca
  #   #   For each row of obronca
  #   #     Find or create 

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


  # # TODO: just import!

  # # class SawaConnector
  # #   list: (Model, done) ->
  # #     $ "The list switch"
  # #     switch Model.modelName 
  # #       when "Lawsuit"
  # #         async.waterfall [
  # #           # Get lawsuits from Sawa DB
  # #           (done) ->
  # #             $ "Getting list of lawsuits"

  # #           # Get claims
  # #           (lawsuits, done) ->
  # #             $ "Populating with claims"
  # #             map = (lawsuit, done) ->
                  
  # #               request = new mssql.Request

  # #               request.query sql, (error, claims) ->
  # #                 if error then return done error
  # #                 lawsuit.claims = claims
  # #                 done null, lawsuit

  # #             async.map lawsuits, map, done

  # #           # Get parties
  # #           (lawsuits, done) ->
  # #             $ "Populating with parties"
  # #             map = (lawsuit, done) ->
  # #               # TODO: only find ident, role and attorney ident
  # #               # Population should be done by application logic
                  
  # #               request = new mssql.Request

  # #               request.query sql, (error, parties) ->
  # #                 if error then return done error
  # #                 lawsuit.parties = parties
  # #                 done null, lawsuit

  # #             async.map lawsuits, map, done

                
  # #         ], done(error, lawsuits) ->
  # #           if error then return done error
  # #           done null, lawsuits 
  # #           # .map (lawsuit) ->
  # #           #  return
  # #           #    repository: lawsuit.

  # #   sync: (document, done) ->

  # # $ "Go!"
  # # Lawsuit = require "../models/Lawsuit"
  # # connector = new SawaConnector
  # # connector.list Lawsuit, (error, lawsuits) ->
  # #   if error then throw error
  # #   do mssql.close
  # #   console.log JSON.stringify lawsuits