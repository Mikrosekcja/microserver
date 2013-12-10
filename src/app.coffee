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

# data    = require "./dummy-data"
# app.get "/", (req, res) ->
#   template = require "./views/index"
#   locals = 
#      suits: data.suits
#     title: "Microserver"
#     page:
#       title: "new lawsuit" 

#   res.send template.call locals

app.get "/suits/:repository/:year/:number", (req, res) ->
  conditions = _.pick req.params, ["repository", "year", "number"]
  

  async.series [
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
    template = require "./views/index"
    res.send template.call res.locals

mongoose.connect "mongodb://localhost/test"
app.listen 31337