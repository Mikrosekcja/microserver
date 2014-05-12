debug     = require "debug"
$         = debug "SyncService:Connector:Sawa:SyncLawsuits"

async     = require "async"
_         = require "lodash"

Statement = require "./SQLStatement"

Lawsuit   = require "../models/Lawsuit"
Subject   = require "../models/Subject"


# Prepare SQL Statements:
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
    and sprawa.d_zakreslenia is null
    :ident
    :repertorium
  order by
    sprawa.ident desc
  """,
  limit       : (value) => if typeof value is "number" and value then "top #{value}" else ""
  ident       : Statement.helpers.where "sprawa.ident",       Number
  repertorium : Statement.helpers.where "repertorium.symbol", String

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

strona = new Statement """
  Select
    strona.ident,
    dane_strony.ident as dane_strony_ident,
    status.nazwa as status
  from 
    strona
    inner join status on strona.id_statusu = status.ident
    inner join dane_strony on strona.id_danych = dane_strony.ident
  where 
    strona.czyus = 0
    and strona.id_sprawy = :id_sprawy
  """,
  id_sprawy: Number

broni = new Statement """
  Select
    id_obroncy
  from
    broni
  where
    id_strony = :id_strony
  """,
  id_strony: Number

module.exports = (options, done) ->
  if not done and typeof options is "function"
    done    = options
    options = {}

  $ "Looking for lawsuits"

  # TODO: It's one hairy async mess! Modularize!

  async.waterfall [
    (done) => sprawa.exec options, done
    (rows, done) => # Create Lawsuit documents
      $ "There are %d lawsuits here.", rows.length
      async.mapSeries rows, # Do we really need that? eachSeries would be less memory hungry probabily.
        (row, done) =>
          async.waterfall [
            (done) => Lawsuit.findOne "_sync.sawa.ident": row.ident, done
            (lawsuit, done) =>
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

            # Collect claims
            (lawsuit, done) => async.waterfall [
              # Get rows from roszczenie and store in lawsuit document
              (done) => 
                console.dir lawsuit
                roszczenie.exec id_sprawy: lawsuit._sync.sawa.ident, done
              # Push claims to lawsuit document
              (rows, done) =>
                $ "Claims for lawsuit %s are %j", lawsuit.reference_sign, rows
                rows.forEach (row) => lawsuit.claims.push
                  type  : "Uznanie postanowienia wzorca umowy za niedozwolone"
                  value : row.opis.trim()
                done null, lawsuit
            ], done

            # Collect parties
            (lawsuit, done) =>
              async.waterfall [
                # Get  Get rows from strona + status
                (done) => strona.exec id_sprawy: lawsuit._sync.sawa.ident, done
                # Prepare parties subdocuments
                (rows, done) =>
                  $ "There are %d party people in this suit. Put on your suit and dance!", rows.length
                  # TODO: sync selected subjects, and then ...
                  # Find subject document
                  async.each rows,
                    (row, done) =>
                      async.parallel
                        subject   : (done) =>
                          async.waterfall [
                            (done) => @syncSubjects dane_strony_ident: row.dane_strony_ident, done
                            (done) => Subject.findOne "_sync.sawa.dane_strony_ident": row.dane_strony_ident, done
                          ], done
                        role      : (done) => done null, row.status.trim()
                        attorneys : (done) =>
                          async.waterfall [
                            # Get rows from broni
                            (done) => broni.exec id_strony: row.ident, done
                            # Find subject documents
                            (rows, done) =>
                              ids = rows.map( (row) => row.id_obroncy )
                              $ "Syncing attorneys with ident in %j", ids
                              @syncSubjects obronca_ident: ids, (error) -> done error, ids
                            (ids, done) =>
                              $ "Looking for attorneys with ident in %j", ids
                              Subject.findOne "_sync.sawa.obronca_ident": $in: ids, (error, attorney) ->
                                $ "Attorney is %s", attorney?.name.full or "no one"
                                done error, attorney
                          ], done
                        (error, party) =>
                          if error then return done error
                          lawsuit.parties.push party
                          $ "Party is %j", party
                          done null
                    (error) => done error, lawsuit
              ], done

            # Get rows from broni
          ], (error, lawsuit) =>
            if error? and error.message is "Already synced" then error = null
            if error then return done error
            lawsuit.save (error) => done error, lawsuit

        done
  ], (error, lawsuits) => done error
    