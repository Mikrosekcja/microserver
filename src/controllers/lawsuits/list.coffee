Lawsuit = require "../../models/Lawsuit"
Subject = require "../../models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver:controllers:lawsuits:list"

module.exports = (req, res) ->

  conditions = _.pick req.params, [
    "repository"
    "year"
  ]

  { query } = req.query
  
  if match = query?.trim().match /^([a-z]+)\s+([0-9]+)\s*\/\s*(([0-9]{2})?[0-9]{2})$/i
    conditions.repository = match[1]
    conditions.number     = Number match[2]
    conditions.year       = Number if match[4] then match[3] else "20" + match[3]

  if match = query?.trim().match /^([0-9]+)\s*\/\s*(([0-9]{2})?[0-9]{2})$/
    conditions.number = Number match[1]
    conditions.year   = Number if match[3] then match[2] else "20" + match[2]
  if query?.trim().match /^[0-9]+$/ then conditions.number = Number query

  if conditions.repository?
    original = conditions.repository
    conditions.repository = new RegExp "^" + conditions.repository + "$", "i"
    conditions.repository.toString = -> original

  $ "conditions are %j", conditions

  if  conditions.repository? and
      conditions.year? and
      conditions.number? then return res.redirect "/lawsuits/#{conditions.repository}/#{conditions.year}/#{conditions.number}"
      

  res.locals { conditions } # This is for monoose queries
  res.locals conditions     # This is to be used in views
  res.locals { query }      # Used here and there :)

  async.parallel
    lawsuits    : (done) -> async.waterfall [
      # Prepare conditions
      # Find matching subjects
      (done) ->
        if not query then return done null

        Subject.find()
        .or("name.last": new RegExp query, "i")
        .or("name.first": new RegExp query, "i")
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

      spec = $group: _id: "$year", total: $sum: 1
      if res.locals.conditions?.repository then spec = [
        $match: res.locals.conditions
        spec
      ]
        
      Lawsuit.aggregate spec, done
    
    count       : (done) -> Lawsuit.count res.locals.conditions, done
    
    (error, data) ->
      if error then throw error

      res.locals data

      template = require "../../views/lawsuits/list"
      res.send template res.locals