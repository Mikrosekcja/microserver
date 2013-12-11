debug   = require "debug"
$       = debug "microserver:views:index"
{
  renderable, text, raw, tag
  doctype, html, head, body
  form, input, button, label
  div, aside
  h2, h3, h4
  p
  span, a, i, strong, pre, small, em
  br, hr
  ul, ol, li
}       = require "teacup"

layout  = require "./layouts/default"

_       = require "lodash"

module.exports = renderable (data) -> 
  layout.call @, =>
    div class: "row", =>
      tag "main", class: "col-xs-12 col-sm-12", =>
        form
            method: "get"
            =>
              div class: "input-group input-group-lg", =>
                input
                  type        : "text"
                  class       : "form-control"
                  placeholder : "We have #{@count} lawsuits in our shop. What are you looking for?"
                  name        : "query"
                  value       : @query
                  data        :
                    shortcut    : "/"
                span class: "input-group-btn", =>
                  button
                    class     : "btn btn-primary"
                    type      : "submit"
                    => i class: "fa fa-question-circle"

        div class: "list-group", =>
          for suit in @lawsuits
            a href: "/suits/#{suit.repository}/#{suit.year}/#{suit.number}", class: "list-group-item", =>
              h4 class: "text-muted list-group-item-heading", =>
                span class: "fa-stack fa-sm", =>
                  i class: "fa fa-stack-2x fa-folder"
                  i class: "fa fa-search fa-stack-1x fa-inverse"

                text " " + suit.reference_sign
              p class: "list-group-item-text", =>              
                roles = _.groupBy suit.parties, "role"
                for role, parties of roles
                  text role + " "
                  attorneys = _.groupBy parties, (party) =>
                    if not party.attorneys? then return ""
                    (attorney.name.full for attorney in party.attorneys).join ", "
                  for attorney, parties of attorneys
                    for party in parties
                      text party.subject.name.full + " "
                    if attorney then text "(" + attorney + ")"
                  do br
            # for claim in suit.claims
            #   if claim.type is "Uznanie postanowienia wzorca umowy za niedozwolone"
            #     small => pre style: "overflow: hidden; max-height: 100px; font-size: 80%", claim.value
