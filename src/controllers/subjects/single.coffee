Lawsuit = require "../../models/Lawsuit"
Subject = require "../../models/Subject"

_         = require "lodash"
async     = require "async"
tokenizer = require "../../tokenizer"


debug   = require "debug"

view    = require "../../views/subjects/single"

$       = debug "microserver:controllers:subjects:single"

module.exports = (req, res) ->
  { query } = req.query
  res.locals { query }

  async.waterfall [
    # Find the guy
    (done)          -> Subject.findById req.params.subject_id, (error, subject) ->
      if error then return done error
      res.locals {subject}
      done null, subject

    # Count his lawsuits
    # TODO: all below should go parallel
    (subject, done) ->
      if not subject then return done Error "Not found"
      async.parallel
        attorney: (done) -> Lawsuit.count "parties.attorneys": subject._id, done
        party   : (done) -> Lawsuit.count "parties.subject"  : subject._id, done
        (error, lawsuits_count) ->
          if error then return done error
          res.locals { lawsuits_count }
          done null, subject

    # Get list of own lawsuits
    (subject, done) ->
      if query?
        { tokens } = tokenizer query
        if tokens? then conditions = $and: ("claims.value": new RegExp token, "i" for token in tokens)

      Lawsuit.find("parties.subject": subject)
        .where(conditions or {})
        .limit(100)
        .populate("parties.subject")
        .populate("parties.attorneys")
        .exec (error, lawsuits) ->
          if error then return done error
          res.locals { lawsuits }
          done null, subject

    
    # Get clients with lawsuits' count for each
    (subject, done) ->
      Lawsuit.aggregate [
        { $match  : "parties.attorneys": subject._id }
        { $unwind : "$parties" }
        { $match  : "parties.attorneys": subject._id }
        { $group  : _id: "$parties.subject", count: $sum: 1 }
        { $sort   : count : -1 }
        { $project: count :  1, _id : 0, subject : "$_id" }
      ], done

    # Populate clients
    (clients, done) ->
      Subject.populate clients, path: "subject", (error, clients) ->
        if error then return done error
        res.locals { clients }
        done null
        # done null, clients


  ], (error) ->
    if error 
      if  error.name is "CastError"  and
          error.type is "ObjectId"   and
          error.path is "_id"           then return res.json error: "Malformed URL"

      if  error.message is "Not found"  then return res.json error: "Not found"
      else
        console.dir error
        throw error


    if req.accepts ["html", "json"] is "json" then res.json _.extend {}, res.locals
    else res.send view res.locals

    
    

