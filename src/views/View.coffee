teacup  = require "teacup"    
fs      = require "fs"
_       = require "underscore.string"

module.exports = (template) -> teacup.renderable template.bind teacup

# TODO: Load helpers and stuff
files   = fs.readdirSync __dirname + "/helpers"
for file in files
  match = file.match /^(.+)\.(js|coffee)$/i
  if match
    name    = _.camelize match[1]
    helper  = require "./helpers/" + match[1]

    teacup[name] = helper

