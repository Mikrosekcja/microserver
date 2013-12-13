View = require "../View"

console.dir View

module.exports = new View (options, content) ->
  @div
    class   : "modal fade"
    id      : options.id
    tabindex: -1
    role    : "dialog"
    ->
      @div class: "modal-dialog", ->
        @div class: "modal-content", ->
          
          @div class: "modal-header", ->
            @button
              type  : "button"
              class : "close"
              data:
                dismiss: "modal"
              aria:
                hidden: true
              -> @i class: "fa fa-remove"
            @h4 options.title
          
          @div class: "modal-body", ->
            content.call @