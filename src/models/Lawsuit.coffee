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
      index     : yes
    role      : String
    attorneys : [
      type      : mongoose.Schema.ObjectId
      ref       : "Subject"
      index     : yes
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

lawsuit.index {
    repository: 1
    year      : 1
    number    : 1
  }, unique: true

# TODO: db.lawsuits.aggregate([{$group: {_id: {repo: "$repository", y: "$year", n: "$number"}, num: {$sum: 1}}}, {$match: {num: {$gt: 1}}}])


lawsuit.virtual("reference_sign")
  .get -> "#{@repository} #{@number} / #{@year.toString().slice -2}"

lawsuit.plugin (require "../SyncService").plugin

module.exports = mongoose.model "Lawsuit", lawsuit