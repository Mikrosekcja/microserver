debug   = require "debug"
$       = debug "microserver:views:lawsuit"

_       = require "lodash"

layout  = require "../layouts/default"
View    = require "../View"

module.exports = new View (data) -> 

  data.subtitle  = "Lawsuit"
  data.icon      = "folder-open-o"
  data.scripts  ?= []
  # data.scripts.push "/js/editables.js"
  data.scripts.push "/js/ajaxify.js"
  data.scripts.push "/js/selects.js"
  data.scripts.push "//cdnjs.cloudflare.com/ajax/libs/select2/3.4.4/select2.min.js"

  data.styles   ?= []
  data.styles.push "//cdnjs.cloudflare.com/ajax/libs/select2/3.4.4/select2.css"
  data.styles.push "/css/select2-bootstrap.css"


  {
    repository
    year
    number
  } = data.lawsuit

  layout data, =>
    @div class: "row", =>
      @tag "main", class: "col-xs-12 col-sm-9", =>
        @h3 "Roszczenia"
        for claim in data.lawsuit.claims
          @h4 => @small claim.type
          @pre claim.value
          
        do @hr
        @h3 "Strony"

        roles = _.groupBy data.lawsuit.parties, "role"
        for role, parties of roles
          @div class: "panel panel-default", => @div class: "panel-body", =>
            @h4 role
            groups = _.groupBy parties, (party) =>
              if not party.attorneys? then ""
              else (attorney.name.full for attorney in party.attorneys).join ", "

            singles = groups[""]
            delete    groups[""]

            party_entry = @renderable (party) =>
              @li =>
                @i class: "fa fa-li fa-user"
                @a href: "/subjects/#{party.subject._id}", party.subject.name.full
                @a 
                  href  : "#"
                  class : "pull-right"
                  data  :
                    ajax  : true
                    type  : "POST"
                    data  : JSON.stringify
                      _method : "PUT"
                      $pull   : parties: _id: party.id
                  -> @i class: "fa fa-minus-square"


            @ul class: "fa-ul party-groups", => for name, parties of groups
              @li => 
                @i class: "fa fa-li fa-briefcase"
                attorneys = _(parties).pluck("attorneys").flatten().uniq("_id").value()                  
                @strong -> for attorney in attorneys
                  @a href: "/subjects/#{attorney._id}", attorney.name.full
                  @text " "

                @ul class: "fa-ul party-group", => party_entry party for party in parties

            if singles? 
              @ul class: "fa-ul party-singles", -> party_entry party for party in singles

                  
        @a
          class : "btn btn-link"
          href: "#"
          data:
            toggle: "modal"
            target: "#add-party"
          -> 
            @i class: "fa fa-plus-square"
            @text " " + "Add party"

        @dialog id: "add-party", title: "Add party to this lawsuit", -> 
          @form
            method: "POST"
            action: "/lawsuits/#{repository}/#{year}/#{number}/parties"
            class : "form"
            role  : "form"
            ->
              @div class: "form-group", =>
                @label
                  for   : "role"
                  "Role"
                @select
                  id    : "role"
                  name  : "role"
                  class : "form-control"
                  data  : select: "true"
                  ->
                    @option role for role in data.roles

              @div class: "form-group", =>
                @label
                  for   : "subject"
                  "Party"
                @input
                  id    : "subject"
                  name  : "subject"
                  class : "form-control"
                  type  : "hidden"
                  data  :
                    select: "true"
                    url   : "/subjects"

              @div class: "form-group", =>
                @label
                  for   : "attorney"
                  "Attorney"
                @input
                  id    : "attorneys"
                  name  : "attorneys"
                  class : "form-control"
                  type  : "hidden"
                  data  :
                    select: "true"
                    url   : "/subjects"

              @div class: "form-group", =>
                @button
                  type  : "submit"
                  class : "btn btn-primary btn-block"
                  ->
                    @i class: "fa fa-check-square"




        @button
          class: "btn btn-block btn-lg"
          type: "button"
          data:
            toggle: "modal"
            target: "#reference_sign_dialog"
          =>
            @i class: "fa fa-edit"
            @text " " + "Edit"

        @dialog id: "reference_sign_dialog", title: "Change lawsuit reference sign", -> 
          @form
            method: "POST"
            class : "form-inline"
            role  : "form"
            =>
              @input type: "hidden", name: "_method", value: "PUT"

              @div class: "form-group", =>
                @label
                  class : "sr-only"
                  for   : "repository"
                  "Repository"
                @select
                  id    : "repository"
                  name  : "repository"
                  class : "form-control"
                  ->
                    @option selected: data.lawsuit.repository is repository, repository for repository in data.repositories

              @div class: "form-group", =>
                @raw "&nbsp;"

              @div class: "form-group", =>
                @label
                  class : "sr-only"
                  for   : "number"
                  "Number"
                @input
                  id    : "number"
                  name  : "number"
                  type  : "number"
                  value : data.lawsuit.number
                  min   : 0
                  class : "form-control"

              @div class: "form-group", =>
                @raw "&nbsp;/&nbsp;"

              @div class: "form-group", =>
                @label
                  class : "sr-only"
                  for   : "year"
                  "Year"
                @input
                  id    : "year"
                  name  : "year"
                  type  : "number"
                  value : data.lawsuit.year
                  max   : (new Date).getFullYear() + 1
                  class : "form-control"

              @div class: "form-group", =>
                @label
                  class : "sr-only"
                  for   : "year"
                  "Year"
                @button
                  type  : "submit"
                  class : "btn btn-primary"
                  ->
                    @i class: "fa fa-check-square"

        do @hr

        if data.prev? then @a class: "btn btn-link", href: "/lawsuits/#{data.prev.repository}/#{data.prev.year}/#{data.prev.number}", =>
          @i class: "fa fa-arrow-left"
          @text " " + data.prev.reference_sign
        
        if data.next? then @a class: "btn btn-link pull-right", href: "/lawsuits/#{data.next.repository}/#{data.next.year}/#{data.next.number}", =>
          @text data.next.reference_sign + " "
          @i class: "fa fa-arrow-right"

        

        # @button 
        #   type  : "button"
        #   class : "btn btn-lg visible-xs pull-right"
        #   data  : toggle: "offcanvas"
        #   => @i class: "icon-expand-alt"

      @aside
        id    : "sidebar"
        class : "con-xs-12 col-sm-3"
        =>
          @div class: "panel panel-default", =>
            @div class: "panel-heading", => @form
              method: "get"
              =>
                @div class: "input-group input-group-sm", =>
                  @input
                    type        : "query"
                    class       : "form-control"
                    placeholder : "Search for similiar case..."
                    name        : "query"
                    value       : data.query
                  @span class: "input-group-btn", =>
                    @button
                      class     : "btn btn-primary"
                      type      : "submit"
                      => @i class: "fa fa-search"

            # @div class: "panel-body", => @div class: "list-group", => for suit in data.lawsuits
            #   @a href: "/lawsuits/#{suit.repository}/#{suit.year}/#{suit.number}", class: "list-group-item", =>
            #     @p class: "text-muted", =>
            #       @span class: "fa-stack fa-sm", =>
            #         @i class: "fa fa-stack-2x fa-folder"
            #         @i class: "fa fa-plus fa-stack-1x fa-inverse"

            #       @text " " + suit.reference_sign

            #     for party in suit.parties
            #       @p => @small =>
            #         @i class: "fa fa-user"
            #         @text " " + party.subject.name.full

            #     for claim in suit.claims
            #       if claim.type is "Uznanie postanowienia wzorca umowy za niedozwolone"
            #         @small => @pre style: "overflow: hidden; max-height: 100px; font-size: 80%", claim.value
