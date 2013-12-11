if not module.parent then do (require "source-map-support").install

express = require "express"
app     = express()

mongoose = require "mongoose" 

Lawsuit = require "./models/Lawsuit"
Subject = require "./models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver"

app.get "/", (req, res) ->

  { query } = req.query

  # if query then conditions = 
  #   $or:
  #     number  : query
  #     parties : name: $or:
  #       first   : new RegExp query
  #       last    : new RegExp query
  #     parties : attorneys: name: $or
  #       first   : new RegExp query
  #       last    : new RegExp query

  async.parallel
    lawsuits: (done) -> async.waterfall [
      # Prepare conditions
      # Find matching subjects
      (done) ->
        if not query then return done null

        Subject.find()
        .or("name.last": new RegExp query, "i")
        .or("name.first": new RegExp query, "i")
        # .or ([
        #   "name.first": new RegExp query
        # ,
        #   "name.last": new RegExp query 
        # ])
        .limit(100)
        .select("_id")
        .exec done

      # Find matching lawsuits
      (subjects, done) ->
        if not done and typeof subjects is "function" then done = subjects
        if not query then return done null

        Lawsuit.find()
        .or("parties.attorneys": $in: subjects)
        .or("parties.subject": $in: subjects)
        .or("claims.value": new RegExp query, "i")
        .limit(100)
        .populate("parties.subject")
        .populate("parties.attorneys")
        .exec done
    ], done
    
    count   : (done) -> Lawsuit.count done
    
    (error, data) ->
      if error then throw error

      res.locals data
      res.locals { query }
      res.locals
        title: "Mikroserver"
        page :
          title : "Mikrosekcja daje radę."
          icon  : "fighter-jet"

      template = require "./views/index"
      res.send template.call res.locals



app.get "/suits/:repository/:year/:number", (req, res) ->
  conditions = _.pick req.params, ["repository", "year", "number"]
  

  async.series [
    # Find this lawsuit
    (done) ->
      $ "Getting %j", conditions
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
    # Find next and previous lawsuit
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
        
        (error, lawsuits) ->
          if error then return done error
          $ "%j", lawsuits
          res.locals lawsuits
          done null

    (done) ->
      r = Math.floor Math.random() * 10000
      $ "Getting dummy suits %d", r
      Lawsuit.find()
        .skip(r)
        .limit(10)
        .populate("parties.subject")
        .exec (error, lawsuits) ->
          if error then return done error
          
          res.locals { lawsuits }

          done null

  ], (error) ->
    if error?
      $ "Error %j", error
      if error.message is "Not found" then return res.send "<strong>Wow! 404</strong><br />We have 40 000 lawsuits, but this one is missing. Sorry :P"
      else throw error
    template = require "./views/lawsuits/single"
    res.send template.call res.locals

mongoose.connect "mongodb://localhost/test"
app.listen 31337