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

    if (element.is "input") and url? then element.select2
      ajax: {
        type
        url
        data    : (query, page) -> { query, page }
        results : (data)  -> 
          results: data.subjects.map (subject) ->
            id: subject._id
            text: subject.name.full
      }    
    else if element.is "select" then do element.select2
    # TODO: else (no url and not input)
