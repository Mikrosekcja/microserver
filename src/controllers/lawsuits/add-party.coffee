Lawsuit = require "../../models/Lawsuit"
Subject = require "../../models/Subject"

_       = require "lodash"
async   = require "async"

debug   = require "debug"

$       = debug "microserver:controllers:lawsuits:add-party"

module.exports = (req, res) ->
    # What to change
    data = _.pick req.body, [
      "subject"
      "attorneys"
      "role"
    ]
    # And where
    conditions = _.pick req.params, [
      "repository"
      "year"
      "number"
    ]

    if not data.subject then return res.send "ERROR: No subject provided." # TODO: Rise an error and handle it later
    $ "Adding party %j to %j", data, conditions


    Lawsuit.findOneAndUpdate conditions, $addToSet: parties: data, (error, lawsuit) ->
      if error then error
      {
        repository
        year
        number
      } = lawsuit

      if req.accepts ["html", "json"] is "json"
        res.json lawsuit
      else
        res.redirect "/lawsuits/#{repository}/#{year}/#{number}"