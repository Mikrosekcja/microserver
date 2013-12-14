jQuery ($) -> 
  # $.fn.editable.defaults.mode = 'inline'

  $(".editable").each (i, element) ->
    element = $ element
    console.dir element
    element.editable()
