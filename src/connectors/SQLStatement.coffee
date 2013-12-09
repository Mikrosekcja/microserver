_     = require "lodash"
mssql = require "mssql"

debug   = require "debug"
$       = debug "SyncService:Connector:Sawa:SQLStatement"

class SQLStatement
  @escape : (string = "") ->
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
      params[name] = allowed[name] value
      if allowed[name].name is "String"
        params[name] = "'#{SQLStatement.escape params[name]}'"
      
      $ "Sanitizing %s %s -> %s", name, value, params[name]
      return params

  @helpers    :
    where       : (column, type, first = no) ->
      (value) ->
        if not value? then return ""

        clause  = "and " unless first 
        clause += column

        switch type.name 
          when "Number" 
            if      typeof value is "number"
              clause += " = #{value}"
            
            else if typeof value is "object" and value.length?
              clause += " in (#{value.map (e) -> Number e})"
            
            else throw Error "Not a number"
          
          when "String"
            if typeof value is "object" and value.length?
              value   = value.map (e) -> "'#{SQLStatement.escape e}'"
              clause += " in (#{value})"
            else
              value = SQLStatement.escape value
              clause += " = '#{value}'"

          else throw Error "Not implemented"

        return clause

  constructor : (@sql, @params) ->
  
  defaults    : {}

  bind        : (fields = {}) ->
    defaults  = @defaults
    defaults[param] ?= null for param of @params

    _.defaults fields, defaults    
    fields  = SQLStatement.sanitize fields, @params
    query   = @sql
    query   = query.replace ":" + name, value for name, value of fields
    return query

  exec        : (fields, done) ->
    if not done and typeof fields is "function"
      done    = fields
      fields  = {}
    
    request = new mssql.Request
    query   = @bind fields
    request.query query, done

module.exports = SQLStatement