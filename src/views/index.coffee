{
  renderable, text, raw, tag
  doctype, html, head, body
  form, input, button
  div, aside
  p
  span, a, i
} = require "teacup"

layout = require "./layouts/default"


module.exports = renderable (data) -> 
  layout.call @, =>
    div class: "row", =>
      tag "main", class: "col-xs-12 col-sm-9", =>
        div class: "jumbotron", =>
          i class: "fa fa-folder-o fa-2x fa-border pull-left"
          p "Case form will go here."
          form
            method: "get"
            =>


        # button 
        #   type  : "button"
        #   class : "btn btn-lg visible-xs pull-right"
        #   data  : toggle: "offcanvas"
        #   => i class: "icon-expand-alt"

      aside
        id    : "sidebar"
        class : "con-xs-12 col-sm-3"
        =>
          div class: "panel panel-default", =>
            form
              method: "get"
              =>
                div class: "input-group input-group-sm", =>
                  input
                    type        : "query"
                    class       : "form-control"
                    placeholder : "Search for similiar case..."
                    name        : "query"
                    value       : @query
                  span class: "input-group-btn", =>
                    button
                      class     : "btn btn-primary"
                      type      : "submit"
                      => i class: "fa fa-search"



