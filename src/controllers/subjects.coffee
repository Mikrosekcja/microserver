Lawsuit = require "../models/Lawsuit"
Subject = require "../models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver:controllers:subjects"

module.exports =
  list: (req, res) ->
    
    conditions  = {}
    { query }   = req.query
    if query then conditions["name.last"] = new RegExp query, "i"

    Subject.find conditions, null, limit: 100, (error, subjects) ->
      if error then throw error
      res.json subjects

  single: (req, res) ->
    async.waterfall [
      (done)          -> Subject.findById req.params.subject_id, done
      (subject, done) ->
        $ "Here"
        if not subject then throw Error "Not found"
        $ "Here"
        res.locals { subject }
        async.parallel
          attorney: (done) -> Lawsuit.find "parties.attorneys": subject._id, done
          party   : (done) -> Lawsuit.find "parties.subject"  : subject._id, done
          done
    ], (error, lawsuits) ->
      $ "Here"
      if error 
        if error.message is "Not found" then res.json error: "Not found"
        else throw error

      $ "Here"
      res.locals {lawsuits}
      console.dir res.locals
      res.json _.pick res.locals, [
        "subject"
        "lawsuits"
      ]

