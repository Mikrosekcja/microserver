debug   = require "debug"
$       = debug "SyncService:Connector:Sawa:SyncSubjects"

async   = require "async"
_       = require "lodash"

mssql   = require "mssql"

Lawsuit = require "../models/Lawsuit"
Subject = require "../models/Subject"

module.exports = (options, done) ->
  if not done and typeof options is "function"
    done    = options
    options = {}

  process.nextTick (done) -> done null, 0

