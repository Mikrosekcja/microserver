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

    @syncSubjects = (require "./syncSubjects").bind @
    @syncLawsuits = (require "./syncLawsuits").bind @


  close: (done) ->
    do mssql.close
    $ "Good bye!"
    process.nextTick done


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
    # (done) -> connector.syncSubjects limit: 5, done
    (done) -> connector.syncLawsuits limit: 4, done
    
    connector.close
  ], (error) ->
    if error then throw error
    do mongoose.connection.close
