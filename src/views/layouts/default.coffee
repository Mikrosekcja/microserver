debug   = require "debug"
$       = debug "microserver:views:layouts:default"

teacup = require "teacup"

layout = teacup.renderable (options, content) -> 
  if not content and typeof options is "function"
    content = options
  @scripts  ?= []
  @styles   ?= []

  @doctype 5
  @html =>
    @head =>
      @title options.title
      @meta charset: "utf-8"
      @meta name: "viewport", content: "width=device-width, initial-scale=1.0"

      @link rel: "stylesheet", href: url for url in [
        "//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.2/css/bootstrap.css"
        "//cdnjs.cloudflare.com/ajax/libs/font-awesome/4.0.3/css/font-awesome.min.css"
      ]
        

    @body data: csrf: options._csrf, =>
      @div class: "container", id: "content", =>
        @header class : "page-header", =>
          @h1 =>
            @i class: "fa fa-" + options.icon if options.icon?
            @text " " + options.title + " "
            @br class: "visible-xs visible-sm"
            @small options.subtitle

        do content
        
      @footer class: "container", =>
        { engine } = options
        @small =>
          @i class: "fa fa-bolt"
          @text " powered by "
          @a
            href  : engine.repo
            target: "_blank"
            engine.name
          @text " v. #{engine.version}. "
          do @wbr
          @text "#{engine.name} is "
          @a 
            href: "/license",
            "a free software"
          @text " by "
          @a href: engine.author?.website, engine.author?.name
          @text ". "
          do @wbr
          @text "Thank you :)"

      # views and controllers can set @styles and @scripts to be appended here
      @script type: "text/javascript", src: url for url in [
        "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js"
        "//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.2/js/bootstrap.min.js"
        "//cdnjs.cloudflare.com/ajax/libs/typeahead.js/0.9.3/typeahead.min.js"
        "//cdnjs.cloudflare.com/ajax/libs/jquery-cookie/1.3.1/jquery.cookie.min.js"
        "https://login.persona.org/include.js"
        "/js/authenticate.js"
      ].concat options.scripts or []

      link rel: "stylesheet", href: url for url in options.styles or []

module.exports = layout.bind teacup
