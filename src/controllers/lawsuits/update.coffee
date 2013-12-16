Lawsuit = require "../../models/Lawsuit"
Subject = require "../../models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver:controllers:lawsuits:update"

module.exports = (req, res) ->
    # What to change
    data = _.pick req.body, [
      "repository"
      "year"
      "number"
      "parties"
    ]
    # And where
    conditions = _.pick req.params, [
      "repository"
      "year"
      "number"
    ]

    $ "Updating %j with %j", conditions, data

    Lawsuit.findOneAndUpdate conditions, data, (error, lawsuit) ->
      if error         
        if error.lastErrorObject?.code is 11001 then return res.send "ERROR: " +
          "There already is a lawsuit with reference sign " + 
          "#{data.repository} #{data.number} / #{data.year}"
        else throw error
      {
        repository
        year
        number
      } = lawsuit

      res.redirect "/lawsuits/#{repository}/#{year}/#{number}"