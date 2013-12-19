debug   = require "debug"
$       = debug "microserver:views:subject:single"

_       = require "lodash"

layout  = require "../layouts/default"
View    = require "../View"

module.exports = new View
  helpers: __dirname + "/../helpers"
  (data) -> 

    data.subtitle  = "Subject"
    data.icon      = "female"
    
    data.scripts  ?= []
    data.scripts.push "/js/ajaxify.js"
    data.scripts.push "/js/selects.js"
    data.scripts.push "//cdnjs.cloudflare.com/ajax/libs/select2/3.4.4/select2.min.js"

    data.styles   ?= []
    data.styles.push "//cdnjs.cloudflare.com/ajax/libs/select2/3.4.4/select2.css"
    data.styles.push "/css/select2-bootstrap.css"


    {
      name
      lawsuits
      clients
    } = data.subject

    data.title = name.full

    layout data, =>
      @div class: "row", =>
        @tag "main", class: "col-xs-12 col-sm-9", =>
          if lawsuits.party then @h3 ->
            @i class: "fa fa-user"
            @text " " + "Party in #{lawsuits.party} lawsuits"
          if lawsuits.attorney 
            @h3 ->
              @i class: "fa fa-suitcase"
              @text " " + "Attorney of #{clients.length} parties in #{lawsuits.attorney} lawsuits"
            @ul class: "fa-ul", -> for client in clients
              @li ->
                @i class: "fa fa-li fa-user"
                @text " "
                @a href: "/subjects/#{client.subject._id}", client.subject.name.full
                @text " (#{client.count})"