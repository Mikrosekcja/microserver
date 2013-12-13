mongoose = require "mongoose"

lawsuit = new mongoose.Schema
  repository: 
    type      : String
    index     : yes
  year      : 
    type      : Number
    index     : yes
  number    : 
    type      : Number
    index     : yes
  file_date : Date
  parties   : [
    subject   :
      type      : mongoose.Schema.ObjectId
      ref       : "Subject"
    role      : String
    attorneys : [
      type      : mongoose.Schema.ObjectId
      ref       : "Subject"
    ]
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