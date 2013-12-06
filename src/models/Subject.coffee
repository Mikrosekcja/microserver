mongoose = require "mongoose"

subject = new mongoose.Schema
  name  :
    first : String
    last  : String

subject.virtual("name.full")
  .get -> "#{@name.first} #{@name.last}"

subject.plugin (require "../SyncService").plugin

module.exports = mongoose.model "Subject", subject