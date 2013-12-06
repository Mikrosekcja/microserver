# # SyncService

# A class and a service to handle MicroDB synchronisation with other systems (Sawa in particular)

if not module.parent then do (require "source-map-support").install

debug = require "debug"

$ = debug "SyncService"

class SyncService
  constructor: ->
    console.log "New sync service!"

  @plugin: (schema) ->
    schema.add _sync: Object

if not module.parent 
  throw Error "Standalone execution not implemented yet. Sorry :P"

else module.exports = SyncService
