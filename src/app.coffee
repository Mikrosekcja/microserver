express = require "express"

app     = express()

data = require "./dummy-data"

app.get "/", (req, res) ->
  template = require "./views/index"
  locals = 
    suits: data.suits
    title: "Microserver"
    page:
      title: "new lawsuit" 

  res.send template.call locals

app.get "/suits", (req, res) ->
  res.json data.suits

app.get "/subjects", (req, res) ->
  res.json data.subjects

app.listen 31337