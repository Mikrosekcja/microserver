debug   = require "debug"
$       = debug "microserver:views:index"

teacup  = require "teacup"
_       = require "lodash"

layout  = require "../layouts/default"
view    = teacup.renderable (data, options = {}) -> 
  _.defaults options,
    _.pick data, [
      "title"
      "subtitle"
      "icon"
      "engine"
    ]

    options.title     = ((data.repository or "") + " " + (data.year or "")).trim() or "Lawsuits"
    options.subtitle  = "We have #{data.count} of them ATM."
    options.icon      = "book"

  layout options, =>
    @div class: "row", =>
      @tag "main", class: "col-xs-12 col-sm-12", =>
        @form
            method: "get"
            =>
              @div class: "input-group input-group-lg", =>
                @input
                  type        : "text"
                  class       : "form-control"
                  placeholder : "We have #{data.count} lawsuits in our shop. What are you looking for?"
                  name        : "query"
                  value       : data.query
                  data        :
                    shortcut    : "/"
                @span class: "input-group-btn", =>
                  @button
                    class     : "btn btn-primary"
                    type      : "submit"
                    => @i class: "fa fa-search"

        do @hr
        if not data.lawsuits? then @div class: "row", ->
          unless data.repository
            $ "Repositories are %j", data.repositories
            repositories = _(data.repositories).sortBy("total").reverse().value()
            $ "Repositories are %j", repositories
            @div class: "row", -> for repository in repositories
              @div class: "col-sm-4 col-md-3", -> @a href: "/lawsuits/#{repository._id}", ->
                @div class: "thumbnail text-center", ->
                  @i class: "fa fa-archive fa-4x"
                  @div class: "caption", ->
                    @h3 repository._id
                    @span class: "badge", repository.total
        
          console.dir data
          if data.repository 
            $ "years are %j", data.years
            years = _(data.years).sortBy("_id").reverse().value()
            $ "years are %j", years
            @div class: "row", -> for year in years
              @div class: "col-sm-4 col-md-3", -> @a href: "/lawsuits/#{data.repository}/#{year._id}", ->
                @div class: "thumbnail text-center", ->
                  @i class: "fa fa-calendar fa-4x"
                  @div class: "caption", ->
                    @h3 year._id
                    @span class: "badge", year.total

          if data.year? then @div class: "jumbotron", ->
            @p "There are #{data.count} #{data.repository} lawsuits from #{data.year}. Search to find."

        else if not data.lawsuits.length then @div class: "alert alert-info", "Nothing like that here."
        
        else @div class: "list-group", =>
          for suit in data.lawsuits
            @a href: "/lawsuits/#{suit.repository}/#{suit.year}/#{suit.number}", class: "list-group-item", =>
              @h4 class: "text-muted list-group-item-heading", =>
                @span class: "fa-stack fa-sm", =>
                  @i class: "fa fa-stack-2x fa-folder"
                  @i class: "fa fa-search fa-stack-1x fa-inverse"

                @text " " + suit.reference_sign
              @p class: "list-group-item-text", =>              
                roles = _.groupBy suit.parties, "role"
                for role, parties of roles
                  @text role + " "
                  attorneys = _.groupBy parties, (party) =>
                    if not party.attorneys? then return ""
                    (attorney.name.full for attorney in party.attorneys).join ", "
                  for attorney, parties of attorneys
                    for party in parties
                      @text party.subject.name.full + " "
                    if attorney then @text "(" + attorney + ")"
                  do @br
              
              for claim in suit.claims
                if claim.type is "Uznanie postanowienia wzorca umowy za niedozwolone"
                  @small => @pre style: "overflow: hidden; max-height: 100px; font-size: 80%", claim.value

module.exports = view.bind teacup