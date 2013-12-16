debug   = require "debug"
path    = require "path"
_       = require "lodash"

$       = debug "microserver:Controller"

class Controller
  constructor : (@options = {}) ->
    
    _(@options).defaults
      routes  : {}
      actions : {}

    @routes   = @options.routes
    @actions  = @options.actions

    # Root directory for controller's modules (see below)
    directory   = @options.root or
                  if module.parent? then path.dirname module.parent?.filename else __dirname

    for name, route of @routes
      # Route can be provided in canonical form as hash: {method: "GET", url: "/foos/:foo_id"} ...
      if typeof route is "object"
        {
          method
          url
        } = route

      # or in short form as string: "GET  /foo/:foo_id"
      else if typeof route is "string"
        [
          method
          url
        ] = route.split /\s+/
      if not (
        method  and typeof method is "string" and
        url     and typeof url    is "string"
      ) then throw Error "Invalid route for action '#{name}'"

      # Lets cast it to canonical form
      method  = method.toLowerCase()
      route   = {
        method
        url
      }
      @routes[name] = route

      # Now lets load a function for this action
      # If they are not provided in options, then we expect them to be stored in files named after action
      # located in the same directory as parent module (the one that requires this)
      if typeof @actions[name] is "function" then @actions[name] = @actions[name].bind @
      else
        module_path = path.resolve directory, name
        $ "Loading function for %s (%s %s) from %s", name, method, url, module_path
        @actions[name]  = (require module_path).bind @
    
  plugInto    : (app) ->
    # console.dir @
    for name, route of @routes
      {
        method
        url
      } = route
      $ "Plugging %s into app.%s %s", name, method, url
      app[method.toLowerCase()] url, @actions[name]
      
module.exports = Controller