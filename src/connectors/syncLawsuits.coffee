debug     = require "debug"
$         = debug "SyncService:Connector:Sawa:SyncSubjects"

async     = require "async"
_         = require "lodash"

Statement = require "./SQLStatement"

Lawsuit   = require "../models/Lawsuit"
Subject   = require "../models/Subject"

module.exports = (options, done) ->
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
                      and roszczenie.czyus = 0
                      and roszczenie.opis is not null
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