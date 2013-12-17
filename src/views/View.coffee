teacup    = require "teacup"    
fs        = require "fs"
_         = require "lodash"
_.string  = require "underscore.string"

module.exports = (options, template) ->
  if not template and typeof options is "function" 
    template  = options
    options   = {}

  switch typeof options.helpers
    when "object" 
      for name, helper in options.helpers when typeof helper is "function"
        teacup[name] = helper.bind teacup

    when "string"
      files   = fs.readdirSync options.helpers
      for file in files
        match = file.match /^(.+)\.(js|coffee)$/i
        if match
          name    = _.string.camelize       match[1]
          helper  = require "./helpers/" +  match[1]

          teacup[name] = helper

  return teacup.renderable template.bind teacup

