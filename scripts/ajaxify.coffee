jQuery ($) -> 
  $("[data-ajax]").each (i, element) ->
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

    element.click ->
      request = $.ajax {
        type
        url
        data
      }
      request.done  -> do window.location.reload
      request.fail  -> console.error "Error :P"
