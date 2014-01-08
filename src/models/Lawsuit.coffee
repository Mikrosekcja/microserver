mongoose = require "mongoose"

lawsuit = new mongoose.Schema
  repository: 
    type      : String
    index     : yes
    required  : yes
  year      : 
    type      : Number
    index     : yes
    required  : yes
  number    : 
    type      : Number
    index     : yes
    required  : yes
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

  history   : [
    # History contains events
    # In future they will be used to calculate curent state of lawsuit (parties, attorneys, etc.)
    # Array of events
    description : 
      type        : String
      required    : yes
      index       : yes
    filed       : 
      on          : 
        type        : Date
        # required    : yes
        index       : yes
      # by          : [
      #   type        : ObjectId
      #   ref         : Subject    
      # ]
    received    : 
      on          : 
        type        : Date
        # required    : yes
        index       : yes

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

module.exports = mongoose.model "Lawsuit", lawsuit