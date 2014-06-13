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
    directory   = @options.directory or
                  # TODO: This is a nasty hack and it bites when using pm2 in cluster mode
                  # SEE : https://github.com/Unitech/pm2#execute-any-script-what-is-fork-mode
                  path.resolve require.main.filename, "..", "controllers/", @options.name

    for name, route of @routes
      # Route can be provided in canonical form as hash: {method: "GET", url: "/foos/:foo_id"} ...
      # URL can be an array of strings for multiple paths

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

      method  = method.toLowerCase()
      if not method in [
        "get"
        "post"
        "put"
        "delete"
      ] then throw Error """
        Invalid method (#{method}) for action '#{name}'
        Method must be one of 'GET', 'POST', 'PUT', 'DELETE'
      """

      # In canonical form url is an array of strings, usually one :)
      if typeof url is "string" then url = [ url ]
      if _.isArray url then url = _.filter url, (e) -> typeof e is "string"
      if not url.length then throw Error """
        Invalid URL for action '#{name}'
        URL must be a string or array of strings.
      """

      # Lets cast it to canonical form
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
        $ "Loading function for %s (%s %j) from %s", name, method, url, module_path
        @actions[name]  = (require module_path).bind @

  plugInto    : (app) ->
    # console.dir @
    for name, route of @routes
      {
        method
        url
      } = route
      for single_url in url
        $ "Plugging %s into app.%s %s", name, method, single_url
        app[method] single_url, @actions[name]

module.exports = Controller
