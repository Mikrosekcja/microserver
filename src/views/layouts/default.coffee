{ 
  renderable, tag, text
  doctype, html, head, body
  title, meta, link, script, style
  header, main, footer, main, aside, div
  h1, h2, p
  a, i, small
  br, wbr
}       = require "teacup"

module.exports = renderable (content) ->  
  @scripts  ?= []
  @styles   ?= []

  doctype 5
  html =>
    head =>
      title @title
      meta charset: "utf-8"
      meta name: "viewport", content: "width=device-width, initial-scale=1.0"

      link rel: "stylesheet", href: url for url in [
        "//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.2/css/bootstrap.css"
        "//cdnjs.cloudflare.com/ajax/libs/font-awesome/4.0.3/css/font-awesome.min.css"
      ]
        

    body data: csrf: @_csrf, =>
      div class: "container", id: "content", =>
        header class : "page-header", =>
          h1 =>
            if @page.icon? then i class: "fa fa-" + @page.icon
            text " " + @title + " "
            br class: "visible-xs visible-sm"
            small @page?.title or @settings?.site.motto

        do content
        
              # @helper "navigation"
              # @helper "profile-box"

      # footer class: "container", =>
      #   small =>
      #     i class: "fa-icon-bolt"
      #     text " powered by "
      #     a
      #       href  : @settings.engine.repo
      #       target: "_blank"
      #       @settings.engine.name
      #     text " v. #{@settings.engine.version}. "
      #     do wbr
      #     text "#{@settings.engine.name} is "
      #     a 
      #       href: "/license",
      #       "a free software"
      #     text " by "
      #     a href: @settings.author?.website, @settings.author?.name
      #     text ". "
      #     do wbr
      #     text "Thank you :)"

      # views and controllers can set @styles and @scripts to be appended here
      script type: "text/javascript", src: url for url in [
        "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js"
        "//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.2/js/bootstrap.min.js"
        "//cdnjs.cloudflare.com/ajax/libs/typeahead.js/0.9.3/typeahead.min.js"
        "//cdnjs.cloudflare.com/ajax/libs/jquery-cookie/1.3.1/jquery.cookie.min.js"
        "https://login.persona.org/include.js"
        "/js/authenticate.js"
      ].concat @scripts or []

      if @styles? then link rel: "stylesheet", href: url for url in @styles
