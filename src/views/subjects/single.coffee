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
      subject         # Our man or corpo
      lawsuits        # Lawsuits in which he/she/it is a party
      lawsuits_count  # Hash { party, attorney }
      clients         # Array of clients with lawsuit count
    } = data

    data.title = subject.name.full

    layout data, =>
      @div class: "row", =>
        @tag "main", class: "col-xs-12 col-sm-9", =>
          if lawsuits_count.party 
            @h3 ->
              @i class: "fa fa-user"
              @text " " + "Party in #{lawsuits_count.party} lawsuits. "

            @form
              method: "get"
              class : "form-inline"
              ->
                @div class: "input-group input-group-sm", ->
                  @input
                    type        : "search"
                    class       : "form-control"
                    placeholder : "There are #{lawsuits_count.party} lawsuits in which #{subject.name.full} is a party. Type to search..."
                    name        : "query"
                    value       : data.query
                    data        :
                      shortcut    : "/"
                  
                  @span class: "input-group-btn", ->
                    @button
                      class     : "btn btn-primary"
                      type      : "submit"
                      -> @i class: "fa fa-search"

            do @hr

            for lawsuit in data.lawsuits
              @div class: "panel panel-default", -> @div class: "panel-body", ->
                @h3 ->
                  @a href: "/lawsuits/#{lawsuit.repository}/#{lawsuit.year}/#{lawsuit.number}", -> @i class: "fa fa-2x fa-folder"
                  @text " "
                  @a href: "/lawsuits/#{lawsuit.repository}/#{lawsuit.year}/#{lawsuit.number}", lawsuit.reference_sign
                  @text " "
                  @small ->
                    # Hackery. Simplify. DRY.
                    roles = _(lawsuit.parties).groupBy("role").value()
                    roles = ({name, parties} for name, parties of roles)
                    roles = _.sortBy roles, "name"

                    for role in roles
                      @text role.name + " "
                      attorneys = _.groupBy role.parties, (party) =>
                        if not party.attorneys? then return ""
                        (attorney.name.full for attorney in party.attorneys).join ", "
                      for attorney, parties of attorneys
                        for party in parties
                          @a href: "/subjects/#{party.subject._id}", party.subject.name.full
                          @text " "
                        if attorney then @text "(" + attorney + ")"
                      
                      @text " ; "

                for claim in lawsuit.claims
                  if claim.type is "Uznanie postanowienia wzorca umowy za niedozwolone"
                    @pre style: "overflow: hidden; max-height: 100px; font-size: 80%", claim.value


          if lawsuits_count.attorney 
            @h3 ->
              @i class: "fa fa-suitcase"
              @text " " + "Attorney of #{clients.length} parties in #{lawsuits_count.attorney} lawsuits"
            @ul class: "fa-ul", -> for client in clients
              @li ->
                @i class: "fa fa-li fa-user"
                @text " "
                @a href: "/subjects/#{client.subject._id}", client.subject.name.full
                @text " (#{client.count})"