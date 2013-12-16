Lawsuit = require "../../models/Lawsuit"
Subject = require "../../models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver:controllers:lawsuits:single"

module.exports = (req, res) ->
  conditions = _.pick req.params, ["repository", "year", "number"]

  async.series [
    # Find this lawsuit
    (done) ->
      Lawsuit.findOne(conditions)
        .populate("parties.subject")
        .populate("parties.attorneys")
        .exec (error, lawsuit) ->
          if error then return done error
          if not lawsuit then return done Error "Not found"
          
          res.locals { lawsuit }
          res.locals
            title: lawsuit.reference_sign
            page :
              title : "Lawsuit"
              icon  : "folder-o"

          done null
    
    # Find next and previous lawsuits and some other things
    (done) ->
      {
        number
        year
        repository
      } = res.locals.lawsuit

      async.parallel
        next: (done) ->
          Lawsuit.find(
              repository: repository
              year      : year
              number    : $gt: number
            )
            .sort(number: 1)
            .limit(1)
            .exec (error, lawsuits) -> done error, lawsuits[0]

        prev: (done) ->
          Lawsuit.find(
              repository: repository
              year      : year
              number    : $lt: number
            )
            .sort(number: -1)
            .limit(1)
            .exec (error, lawsuits) -> done error, lawsuits[0]

        repositories: (done) -> Lawsuit.distinct "repository", done
        claim_types : (done) -> Lawsuit.distinct "claims.type", done
        roles       : (done) -> Lawsuit.distinct "parties.role", done
        count       : (done) -> Lawsuit.count done
        
        (error, data) ->
          if error then return done error
          res.locals data
          done null

  ], (error) ->
    if error?
      $ "Error %j", error
      if error.message is "Not found" then return res.send "<strong>404 &times Congratulations!</strong><br />We have more then 40 000 lawsuits, but this one is missing. Sorry :P"
      else throw error

    template = require "../../views/lawsuits/single"
    res.send template res.locals