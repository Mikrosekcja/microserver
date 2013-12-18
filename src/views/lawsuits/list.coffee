debug   = require "debug"
$       = debug "microserver:views:index"

_       = require "lodash"

View    = require "../View"
layout  = require "../layouts/default"

module.exports = new View
  helpers: __dirname + "/../helpers"
  (data) -> 

    # Setup some data before we pass it to layout
    # It could be argued that this kind of stuff belongs to controller,
    # but I believe it is so view related that it should go here.

    data.title     = ((data.repository or "") + " " + (data.year or "")).trim() or "Lawsuits"
    data.subtitle  = "We have #{data.count} of them ATM."
    data.icon      = if data.year? then "calendar" else if data.repository? then "archive" else "book"                        

    layout data, -> 
      @div class: "row", style: "margin-bottom: 15px", -> @div class: "col-xs-12 col-sm-12", ->
        @form
          method: "get"
          =>
            @div class: "input-group input-group-lg", =>
              @input
                type        : "search"
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

      @tag "main", class: "row", ->
        if not data.lawsuits? and not data.subjects?

          if data.year?
            # We are inside @a single year of @a single repository - show message
            @div class: "col-xs-12", -> @div class: "jumbotron", ->
              @p "There are #{data.count} #{data.repository} lawsuits from #{data.year}. Search to find."


          else if data.repository?
            # We are inside @a single repository - show list of years
            years = _(data.years).sortBy("_id").reverse().value()
            for year in years
              @div class: "col-sm-4 col-md-3", -> @a href: "/lawsuits/#{data.repository}/#{year._id}", ->
                @div class: "thumbnail text-center", ->
                  @i class: "fa fa-calendar fa-4x"
                  @div class: "caption", ->
                    @h3 year._id
                    @span class: "badge", year.total

          else
            # We are outside - show list of repositories
            repositories = _(data.repositories).sortBy("total").reverse().value()
            for repository in repositories
              @div class: "col-sm-4 col-md-3", -> @a href: "/lawsuits/#{repository._id}", ->
                @div class: "thumbnail text-center", ->
                  @i class: "fa fa-archive fa-4x"
                  @div class: "caption", ->
                    @h3 repository._id
                    @span class: "badge", repository.total
        


        else if not data.lawsuits.length and not data.subjects.length
          @div class: "col-xs-12", ->
            @div class: "alert alert-info", "Nothing like that here."
        
        else
          @div class: "col-xs-12", ->
            if data.subjects.length
              @h2 -> @small "Subjects"
              @div class: "row", ->
                for subject in data.subjects
                  @div class: "col-sm-4 col-md-3", -> @a href: "/subjects/#{subject._id}", ->
                    @div class: "thumbnail text-center", ->
                      @i class: "fa fa-user fa-4x"
                      @div class: "caption", style: "height: 100px; overflow: hidden", ->
                        @p -> @strong subject.name.full
                        if subject.lawsuits.attorney then @p ->
                          @i class: "fa fa-suitcase"
                          @text " " + subject.lawsuits.attorney
                        if subject.lawsuits.party then @p ->
                          @i class: "fa fa-user"
                          @text " " + subject.lawsuits.party



            if data.lawsuits.length
              @h2 -> @small "Lawsuits"
              @div class: "row", ->
              for suit in data.lawsuits
                @div class: "panel panel-default", -> @div class: "panel-body", ->
                  @h3 ->
                    @a href: "/lawsuits/#{suit.repository}/#{suit.year}/#{suit.number}", -> @i class: "fa fa-2x fa-folder"
                    @text " "
                    @a href: "/lawsuits/#{suit.repository}/#{suit.year}/#{suit.number}", suit.reference_sign
                    @text " "
                    @small ->
                      roles = _.groupBy suit.parties, "role"
                      for role, parties of roles
                        @text role + " "
                        attorneys = _.groupBy parties, (party) =>
                          if not party.attorneys? then return ""
                          (attorney.name.full for attorney in party.attorneys).join ", "
                        for attorney, parties of attorneys
                          for party in parties
                            @a href: "/subjects/#{party.subject._id}", party.subject.name.full
                            @text " "
                          if attorney then @text "(" + attorney + ")"
                        
                        @text " ; "

                  for claim in suit.claims
                    if claim.type is "Uznanie postanowienia wzorca umowy za niedozwolone"
                      @pre style: "overflow: hidden; max-height: 100px; font-size: 80%", claim.value
