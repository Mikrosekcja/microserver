_     = require "lodash"
mssql = require "mssql"

debug   = require "debug"
$       = debug "SyncService:Connector:Sawa:SQLStatement"

class SQLStatement
  @escape : (string) ->
    string.replace ///
      [
        \0
        \x08
        \x09
        \x1a
        \n
        \r
        "
        '
        \\
        \%
      ]
    ///g, (char) ->
      switch char
        when "\0"   then return "\\0"
        when "\x08" then return "\\b";
        when "\x09" then return "\\t";
        when "\x1a" then return "\\z";
        when "\n"   then return "\\n";
        when "\r"   then return "\\r";
        else return "\\"+char

  @sanitize   : (provided = {}, allowed = {}) ->
    # Allowed shoud have field name as a property name and function as a value
    # eg. id: Number, username: String
    params = _.pick provided, _.keys allowed
    params = _.transform params, (params, value, name) ->
      $ "Sanitizing %s %s", name, value
      params[name] = allowed[name] value
      if allowed[name].name is "String"
        params[name] = "'#{SQLStatement.escape params[name]}'"
        
      return params

  constructor : (@sql, @params) ->
  
  defaults    : {}

  bind        : (fields = {}) ->
    _.defaults fields, @defaults
    fields  = SQLStatement.sanitize fields, @params
    query   = @sql
    query   = query.replace ":" + name, value for name, value of fields
    return query

  exec: (fields, done) ->
    request = new mssql.Request
    query   = @bind fields

module.exports = SQLStatement