###

This module reads two [CSON][] files placed in root directory of app:
  * defaults.cson
  * config.cson

`config.cson` is optional.

`default.cson` is not to be edited by end user.

###

_     = require 'lodash'
path  = require 'path'
cson  = require 'cson'

defaults    = cson.parseFileSync path.resolve __dirname, "../defaults.cson"
try config  = cson.parseFileSync path.resolve __dirname, "../config.cson"
catch error
  if error.code is 'ENOENT' then config = {}
  else throw error

module.exports = _.merge defaults, config

###

[CSON]: https://github.com/bevry/cson

###
