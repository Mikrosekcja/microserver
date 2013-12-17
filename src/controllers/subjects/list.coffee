Lawsuit = require "../../models/Lawsuit"
Subject = require "../../models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver:controllers:subjects:list"

module.exports = (req, res) ->
  conditions  = {}
  { query }   = req.query
  if query then conditions["name.last"] = new RegExp query, "i"

  Subject.find conditions, null, limit: 100, (error, subjects) ->
    if error then throw error
    res.locals {subjects}

    res.json _.extend {}, res.locals
