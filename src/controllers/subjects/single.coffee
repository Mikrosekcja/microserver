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
        attorney: (done) -> Lawsuit.count "parties.attorneys": subject._id, done
        party   : (done) -> Lawsuit.count "parties.subject"  : subject._id, done
        done
    # Count clients. Takes forever ATM:
    # (subject, done) ->
    #   Lawsuit.aggregate [
    #     $unwind : "parties"
    #   ,
    #   #   $match  :
    #   #     "attorneys": subject._id
    #   # ,
    #     $group  :
    #       _id     : "$parties.subject"
    #       total   : $sum: 1
    #   ], (error, clients) ->
    #     if error then return done error
    #     $ "Clients of %s: %j", subject.name.full, clients
    #     subject.clients = clients
    #     done null, subject
  ], (error, lawsuits) ->
    if error 
      if error.message is "Not found" then res.json error: "Not found"
      else throw error

    res.locals {lawsuits}
    res.json _.extend {}, res.locals

