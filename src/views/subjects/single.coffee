debug   = require "debug"
$       = debug "microserver:views:subject:single"

_         = require "lodash"
_.string  = require "underscore.string"
words     = require "underscore.string.words"

layout    = require "../layouts/default"
View      = require "teacup-view"

module.exports = new View
  components: __dirname + "/../components"
  (data) -> 
    $ "Runninkg view"

    {
      subject         # Our man or corpo
      lawsuits        # Lawsuits in which he/she/it is a party
      lawsuits_count  # Hash { party, attorney }
      clients         # Array of clients with lawsuit count
      query
    } = data

    subtitle = ""
    if lawsuits_count.party    then subtitle += "party in #{lawsuits_count.party} lawsuits "
    if lawsuits_count.attorney then subtitle += "attorney of #{clients.length} in #{lawsuits_count.attorney} lawsuits"

    data.subtitle  = subtitle
    data.icon      = "female"
    
    data.scripts  ?= []
    data.scripts.push "/js/ajaxify.js"
    data.scripts.push "/js/selects.js"
    data.scripts.push "//cdnjs.cloudflare.com/ajax/libs/select2/3.4.4/select2.min.js"

    data.styles   ?= []
    data.styles.push "//cdnjs.cloudflare.com/ajax/libs/select2/3.4.4/select2.css"
    data.styles.push "/css/select2-bootstrap.css"



    data.title = subject.name.full

    layout data, =>
      @div class: "row", =>
        @tag "main", class: "col-xs-12 col-sm-9", =>
          if lawsuits_count.party 

            @form
              method: "get"
              class : "form-inline hidden-print"
              ->
                @div class: "input-group input-group-sm", ->
                  @input
                    type        : "search"
                    class       : "form-control"
                    placeholder : "There are #{lawsuits_count.party} lawsuits in which #{subject.name.full} is a party. Type to search..."
                    name        : "query"
                    value       : query
                    data        :
                      shortcut    : "/"
                  
                  @span class: "input-group-btn", ->
                    if query then @a
                      class     : "btn btn-default"
                      href      : "?"
                      -> @i class: "fa fa-times"
                    @button
                      class     : "btn btn-primary"
                      type      : "submit"
                      -> @i class: "fa fa-search"


            if query then @div class: "visible-print clearfix", ->
              @p ->
                @strong "Query: "
                @text data.query
              @p class: "pull-right", ->
                @em " " + "#{lawsuits.length} matching"


            do @hr

            for lawsuit in data.lawsuits
              id = _.string.slugify lawsuit.reference_sign

              @div
                id    : id
                class : "lawsuit panel panel-default"
                ->
                  @div class: "panel-body", ->
                    @h4 ->
                      @a
                        href: "/lawsuits/#{lawsuit.repository}/#{lawsuit.year}/#{lawsuit.number}"
                        -> @i class: "fa fa-fw fa-folder-o pull-left"
                      @a
                        href: "/lawsuits/#{lawsuit.repository}/#{lawsuit.year}/#{lawsuit.number}"
                        lawsuit.reference_sign
                      do @br
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

                    for claim, i in lawsuit.claims
                      if claim.type is "Uznanie postanowienia wzorca umowy za niedozwolone"
                        @pre 
                          id    : id + "-" + i
                          class : "claim"
                          style : "overflow: hidden; max-height: 100px; font-size: 80%"
                          =>
                            @text claim.value
                            @a
                              class : "btn btn-link btn-xs pull-right hidden-print"
                              href  : "?query=" + words(claim.value)?.join "+"
                              ->
                                @i class: "fa fa-search"
                                @text " " + "similar"


          if lawsuits_count.attorney 
            @h6 ->
              @i class: "fa fa-suitcase"
              @text " " + "Attorney of #{clients.length} parties in #{lawsuits_count.attorney} lawsuits"
            @ul class: "fa-ul", -> for client in clients
              @li ->
                @i class: "fa fa-li fa-user"
                @text " "
                @a href: "/subjects/#{client.subject._id}", client.subject.name.full
                @text " (#{client.count})"