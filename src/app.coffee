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

pkg     = require "../package.json"

engine  =
  name:     "Microserver"
  version:  pkg.version
  repo:     pkg.repo

author = pkg.author.match ///
  ^
  \s*
  ([^<\(]+)     # name
  \s+
  (?:<(.*)>)?   # e-mail
  \s*
  (?:\((.*)\))? # website
  \s*
///
engine.author =
    name    : do author[1]?.trim
    email   : do author[2]?.trim
    website : do author[3]?.trim

app.use (req, res, next) ->
  # Set default values for res.locals
  res.locals
    title   : "Mikroserver"
    subtitle: "Mikrosekcja daje radę."
    icon    : "fighter-jet"
    engine  : engine

  do next

app.get "/", (req, res) -> res.redirect "/lawsuits"

get_lawsuits = (req, res) ->

  { query } = req.query

  async.parallel
    lawsuits    : (done) -> async.waterfall [
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

        Lawsuit.find(res.locals.conditions)
        .or("parties.attorneys": $in: subjects)
        .or("parties.subject": $in: subjects)
        .or("claims.value": new RegExp query, "i")
        .limit(100)
        .populate("parties.subject")
        .populate("parties.attorneys")
        .exec done
    ], done

    repositories: (done) ->
      if res.locals.conditions?.repository then return done null, []
      Lawsuit.aggregate
        $group: _id: "$repository", total: $sum: 1
        done

    years       : (done) ->
      if res.locals.conditions?.year       then return done null, []

      Lawsuit.aggregate
        # $match: res.locals.conditions or {}
        $group: _id: "$year", total: $sum: 1
        done
    
    count       : (done) -> Lawsuit.count res.locals.conditions, done
    
    (error, data) ->
      if error then throw error

      res.locals data
      res.locals { query }

      template = require "./views/lawsuits/list"
      res.send template res.locals


app.get "/lawsuits", get_lawsuits

app.get "/lawsuits/:repository", (req, res, next) ->
  res.locals.conditions = repository: req.params.repository
  res.locals.repository = req.params.repository
  do next

app.get "/lawsuits/:repository", get_lawsuits

app.get "/lawsuits/:repository/:year", (req, res, next) ->
  res.locals.conditions =
    repository: req.params.repository
    year      : req.params.year

  res.locals
    repository: req.params.repository
    year      : req.params.year

  do next

app.get "/lawsuits/:repository/:year", get_lawsuits


app.get "/lawsuits/:repository/:year/:number", (req, res) ->
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
    res.send template res.locals

mongoose.connect "mongodb://localhost/test"
app.listen 31337