mongoose = require "mongoose"

subject = new mongoose.Schema
  name  :
    first : String
    last  : String
  _sync : Object

subject.set "toJSON"  , virtuals: true
subject.set "toObject", virtuals: true

subject.virtual("name.full")
  .get -> 
    if @name.first then "#{@name.first } #{@name.last}"
    else @name.last
  
module.exports = mongoose.model "Subject", subject