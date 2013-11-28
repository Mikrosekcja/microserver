express = require "express"

app     = express()

app.get "/", (req, res) ->
  template = require "./views/index"
  res.send template.call title: "Welcome to Microserver"

app.listen 31337