Lawsuit = require "../../models/Lawsuit"
Subject = require "../../models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver:controllers:subjects:single"

module.exports = (req, res) ->
  async.waterfall [
    (done)          -> Subject.findById req.params.subject_id, done
    (subject, done) ->
      if not subject then throw Error "Not found"
      res.locals { subject }
      async.parallel
        attorney: (done) -> Lawsuit.find "parties.attorneys": subject._id, done
        party   : (done) -> Lawsuit.find "parties.subject"  : subject._id, done
        done
  ], (error, lawsuits) ->
    if error 
      if error.message is "Not found" then res.json error: "Not found"
      else throw error

    res.locals {lawsuits}
    res.json _.extend {}, res.locals

