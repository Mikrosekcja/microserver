debug   = require "debug"
$       = debug "microserver:views:layouts:default"

View    = require "teacup-view"

module.exports = new View components: __dirname + "/../components", (data, content) -> 

  if not content and typeof data is "function"
    content = data
  
  data.scripts  ?= []
  data.styles   ?= []

  @doctype 5
  @html =>
    @head =>
      @title data.title
      @meta charset: "utf-8"
      @meta name: "viewport", content: "width=device-width, initial-scale=1.0"

      @link rel: "stylesheet", href: url for url in [
        "//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.2/css/bootstrap.css"
        "//cdnjs.cloudflare.com/ajax/libs/font-awesome/4.0.3/css/font-awesome.min.css"
        "/css/microserver.css"
      ]        

    @body data: csrf: data._csrf, =>
      @div class: "container", id: "content", =>
        @header class : "page-header", =>
          @h1 =>
            @i class: "fa fa-" + data.icon if data.icon?
            @text " " + data.title + " "
            @br class: "visible-xs visible-sm"
            @small data.subtitle

            @a
              href  : "/"
              class : "btn btn-default btn-lg pull-right"
              ->
                @i class: "fa fa-home"

        content.call @
        
      @footer class: "container", =>
        { engine } = data
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
      ].concat data.scripts or []

      @link rel: "stylesheet", href: url for url in data.styles or []
      @style type: "text/css", """
        .select2-offscreen,
        .select2-offscreen:focus {
          // Keep original element in the same spot
          // So that HTML5 valiation message appear in the correct position
          left: auto !important;
          top: auto !important;
        }
      """



