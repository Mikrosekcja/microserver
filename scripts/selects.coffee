jQuery ($) -> 
  $("[data-select]").each (i, element) ->
    element = $ element
    console.dir element
    # TODO: browserify lodash
    {
      type
      data
      url
    } = do element.data

    type  ?= "GET"
    url   ?= window.location.pathname

    element.select2 
      ajax: {
        type
        url
        data  : (query) ->
        result: (data)  ->
        # http://ivaynberg.github.io/select2/
        # Uncaught Error: Option 'ajax' is not allowed for Select2 when attached to a <select> element. 
      }
