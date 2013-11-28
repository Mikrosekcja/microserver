{
  renderable, text, raw, tag
  doctype, html, head, body
  form, input, button, label
  div, aside
  h2, h3
  p
  span, a, i, strong
  br, hr
} = require "teacup"

layout = require "./layouts/default"


module.exports = renderable (data) -> 
  layout.call @, =>
    div class: "row", =>
      tag "main", class: "col-xs-12 col-sm-9", =>
        div class: "jumbotron", =>
          h2 =>
            i class: "fa fa-folder-open-o"

            text " " + "12 234 325 325 / 14"
          do hr
          form
            method: "get"
            class : "form-horizontal"
            =>
              div class: "form-group", =>
                label
                  for   : "date"
                  class : "col-sm-6"
                  "Submission date"
                div class: "col-sm-6", =>
                  input 
                    id    : "date"
                    value : "2014-03-22"
                    name  : "date"
                    type  : "text"
                    class : "form-control"

              div class: "form-group", =>
                p class: "text-center text-muted", => i class: "fa fa-ellipsis-h fa-2x"

              div class: "form-group", =>
                button
                  class: "btn btn-block btn-primary btn-lg"
                  type: "submit"
                  =>
                    i class: "fa fa-plus-circle"
                    text " " + "save"

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
            div class: "panel-heading", => form
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

            div class: "panel-body", => div class: "list-group", => for suit in @suits
              a href: "#", class: "list-group-item", =>
                h3 class: "text-muted", =>
                  span class: "fa-stack fa-sm", =>
                    i class: "fa fa-stack-2x fa-folder"
                    i class: "fa fa-plus fa-stack-1x fa-inverse"

                  text " " + suit.index + " / " + suit.year.toString().slice 2

                p suit.summary               

                



