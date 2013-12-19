Lawsuit = require "../../models/Lawsuit"
Subject = require "../../models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver:controllers:subjects:single"

module.exports = (req, res) ->
  async.waterfall [
    # Find the guy
    (done)          -> Subject.findById req.params.subject_id, done

    # Count his lawsuits
    (subject, done) ->
      if not subject then throw Error "Not found"
      subject = subject.toObject()
      async.parallel
        attorney: (done) -> Lawsuit.count "parties.attorneys": subject._id, done
        party   : (done) -> Lawsuit.count "parties.subject"  : subject._id, done
        (error, lawsuits) ->
          if error then return done error
          subject.lawsuits = lawsuits
          done null, subject
    
    # Count clients. Takes forever ATM:
    (subject, done) ->
      Lawsuit.aggregate [
        { $match  : "parties.attorneys": subject._id }
        { $unwind : "$parties" }
        { $match  : "parties.attorneys": subject._id }
        { $group  : _id: "$parties.subject", count: $sum: 1 }
        { $sort   : count : -1 }
        { $project: count :  1, _id : 0, subject : "$_id" }
      ], (error, clients) ->
        if error then return done error
        subject.clients = clients
        done null, subject

    # Populate clients
    (subject, done) ->
      Subject.populate subject, path: "clients.subject", done
  ], (error, subject) ->
    if error 
      if  error.name is "CastError"  and
          error.type is "ObjectId"   and
          error.path is "_id"           then return res.json error: "Malformed URL"

      if  error.message is "Not found"  then return res.json error: "Not found"
      else
        console.dir error
        throw error

    res.locals {subject}
    res.json _.extend {}, res.locals

