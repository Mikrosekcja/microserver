debug   = require "debug"


async   = require "async"
_       = require "lodash"

mssql   = require "mssql"

Subject = require "../models/Subject"

Statement = require "./SQLStatement"

# Prepare SQL Statements

dane_strony = new Statement """
  Select :limit
    ident,
    imie,
    nazwisko,
    plec,
    fizpraw,
    pesel,
    nip,
    krs,
    regon
  from 
    dane_strony
  where 
    czyus = 0
    and nazwisko is not null
    :dane_strony_ident
  """,
  limit             : (value) -> if typeof value is "number" and value then "top #{value}" else ""
  dane_strony_ident : Statement.helpers.where "ident", Number
  # TODO: if no first nor last name then rise an error and handle it down the drain

obronca = new Statement """
  Select :limit
    ident,
    imie,
    nazwisko,
    tytul,
    plec,
    pesel
  from 
    obronca
  where 
    czyus = 0
    and nazwisko is not null
    :obronca_ident
  """,
  limit         : (value) -> if typeof value is "number" and value then "top #{value}" else ""
  obronca_ident : Statement.helpers.where "ident", Number
  # TODO: if no first nor last name then rise an error and handle it down the drain

module.exports = (options, done) ->
  $ = debug "SyncService:Connector:Sawa:SyncSubjects"
  if not done and typeof options is "function"
    done    = options
    options = {}

  $ "%j", options
  if options.dane_strony_ident? then $ = $.narrow "DSI(#{options.dane_strony_ident})"
  if options.obronca_ident?     then $ = $.narrow "OI(#{options.obronca_ident})"

  async.parallel [
    # EACH 1: Get subjects from Sawa's dane_strony table
    (done) -> async.waterfall [
      # Get rows from dane strony
      (done) ->
        if options.obronca_ident? and not options.dane_strony_ident? then return done null, []
        if options.dane_strony_ident?.length is 0 then return done null, []
        $ "Looking for parties!"
        dane_strony.exec options, done

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
    ], done
  ,
    # EACH 2: Get subjects from Sawa's obronca table
    (done) -> async.waterfall [
      # Get rows from obronca
      (done) ->
        if options.dane_strony_ident? and not options.obronca_ident? then return done null, []
        if options.obronca_ident?.length is 0 then return done null, []
        $ "Looking for attorneys!"
        obronca.exec options, done

      # Find or create subject documents
      (rows, done) ->
        $ "There are %d attorneys.", rows.length
        async.mapSeries rows, # Do we really need that? eachSeries would be less memory hungry probabily.
          (row, done) ->
            async.waterfall [
              # TODO: DRY - it's almost the same as in dane_strony
              (done) -> Subject.findOne "_sync.sawa.obronca_ident": row.ident, done
              (subject, done) ->
                $ "Subject is %j", subject
                
                if subject 
                  $ "We know that attorney! It's %s!", subject.name.full
                  # TODO: compare and sync
                  return done null, subject
                
                else 
                  subject = new Subject
                    name      :
                      first     : row.imie?.trim()
                      last      : row.nazwisko?.trim()
                    _sync     :
                      sawa      :
                        last          : new Date
                        obronca_ident : row.ident

                  $ "There's a new attorney. Allow me to introduce %s.", subject.name.full
                  subject.save (error) -> done error, subject
            ], done 
          done # Finding or creating subject document
    ], done
  ], (error) -> done error
