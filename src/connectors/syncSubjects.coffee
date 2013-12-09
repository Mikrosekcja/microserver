debug   = require "debug"
$       = debug "SyncService:Connector:Sawa:SyncSubjects"

async   = require "async"
_       = require "lodash"

mssql   = require "mssql"

Subject = require "../models/Subject"

Statement = require "./SQLStatement"

module.exports = (options, done) ->
  if not done and typeof options is "function"
    done    = options
    options = {}

  async.waterfall [

    # Get rows from strona + status + dane strony
    (done) ->
      $ "Looking for people!"

      # TODO: if no first nor last name then rise an error and handle it down the drain
      dane_strony = new Statement """
        Select :limit
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
          :ident
        """,
        limit: (value) -> if typeof value is "number" and value then "top #{value}" else ""
        ident: (value) ->
          if typeof value is "number" and value
            "and dane_strony.ident = #{value}"
          else if typeof value is "object" and value.length?
            value = value.map (e) -> Number e
            "and dane_strony.ident in (#{value})"
          else
            ""

      dane_strony.defaults =
        limit     : null
        ident     : null

      fields = _.pick options, ["limit", "ident"]
      dane_strony.exec fields, done

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
