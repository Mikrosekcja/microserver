if not module.parent then do (require "source-map-support").install

# TODO: Investigate Edge.js + Iron Python feasibility to communicate with MSSQL
# SEE:  http://blog.jonathanchannon.com/2013/12/20/using-sql-server-with-nodejs/

debug     = require "debug"
config    = require "config-object"
async     = require "async"
_         = require "lodash"
mssql     = require "mssql"
Statement = require "./SQLStatement"

Lawsuit   = require "../models/Lawsuit"
Subject   = require "../models/Subject"

config.load [
  '../../defaults.cson'
  '../../config.cson'
]

$       = debug "SyncService:Connector:Sawa"

class SawaConnector
  constructor: (config, done) ->
    # TODO: @connection = new mssql.Connection ...
    # Have to deal with async nature of connect
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
  # TODO: Use CSON configuration (as in app.js)

  mongoose = require "mongoose"

  # TODO: use configuration, preferably in cson (like in Dredd)
  mongoose.connect config.mongo.url.join ','

  connector = new SawaConnector config.get "sawa"
  async.series [
    (done) -> async.parallel
      subjects: (done) -> Subject.remove done
      lawsuits: (done) -> Lawsuit.remove done
      done

    # Sync subjects
    # (done) -> connector.syncSubjects limit: 5, done
    (done) -> connector.syncLawsuits done

    connector.close
  ], (error) ->
    if error then throw error
    do mongoose.connection.close
