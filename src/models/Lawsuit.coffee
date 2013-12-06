mongoose = require "mongoose"

lawsuit = new mongoose.Schema
  repository: String
  year      : Number
  number    : Number
  file_date : Date
  parties   : [
    subject   :
      type      : mongoose.Schema.ObjectId
      ref       : "Subject"
    role      : String
    attorney  :
      type      : mongoose.Schema.ObjectId
      ref       : "Subject"
  ]
  claims    : [
    type      : 
      type      : String
    value     : String
  ]
  # TODO:
  # staff     : [
  #   person    :
  #     type      : mongoose.Schema.ObjectId
  #     ref       : "Employee"
  # ]



lawsuit.virtual("reference_sign")
  .get -> "#{@repository} #{@number} / #{@year.toString().slice -2}"

lawsuit.plugin (require "../SyncService").plugin

module.exports = mongoose.model "Lawsuit", lawsuit