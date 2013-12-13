debug   = require "debug"
$       = debug "microserver:views:lawsuit"

_       = require "lodash"

layout  = require "../layouts/default"
View    = require "../View"

module.exports = new View (data) -> 

  data.subtitle  = "Lawsuit"
  data.icon      = "folder-open-o"

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
            attorneys = _.groupBy parties, (party) =>
              $ "Grouping by attorneys"
              if not party.attorneys? then return ""
              names = (attorney.name.full for attorney in party.attorneys).join ", "
              $ "Reduced names are %j", names
              names

            @ul class: "fa-ul", => for attorney, parties of attorneys
              @li => 
                if attorney 
                  @i class: "fa fa-li fa-briefcase"
                  @strong attorney
                @ul class: "fa-ul", => for party in parties
                  @li =>
                    @i class: "fa-li fa fa-user"
                    @a href: "#", party.subject.name.full
            

        # @form
        #   method: "get"
        #   class : "form-horizontal"
        #   =>
        #     @div class: "form-group", =>
        #       @label
        #         for   : "date"
        #         class : "col-sm-6"
        #         "Submission date"
        #       @div class: "col-sm-6", =>
        #         @input 
        #           id    : "date"
        #           value : data.lawsuit.file_date
        #           name  : "date"
        #           type  : "text"
        #           class : "form-control"

        #     @div class: "form-group", =>
        #       @p class: "text-center text-muted", => @i class: "fa fa-ellipsis-h fa-2x"

            # @div class: "form-group", =>
        @button
          class: "btn btn-block btn-primary btn-lg"
          type: "submit"
          =>
            @i class: "fa fa-edit"
            @text " " + "zmień dane"

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
