mongoose = require "mongoose"

subject = new mongoose.Schema
  name  :
    first : String
    last  : String

subject.virtual("name.full")
  .get -> 
    if @name.first then "#{@name.first } #{@name.last}"
    else @name.last
  

subject.plugin (require "../SyncService").plugin

module.exports = mongoose.model "Subject", subject