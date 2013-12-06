do (require "source-map-support").install

SQLStatement  = require "../lib/connectors/SQLStatement"

describe "SQLStatement", ->
  describe "Static methods", ->
    it "can escape SQL strings", ->
      (SQLStatement.escape "Jacek").should.equal "Jacek"
      (SQLStatement.escape "Jacek\"; Drop database jacki; ...").should.equal "Jacek\\\"; Drop database jacki; ..."
    it "can sanitize input parameters", ->
      spec =
        id  : Number
        name: String

      (SQLStatement.sanitize id: 42, name: 1001, bad: ";drop database jacki;", spec).should.eql 
        id  : 42
        name: "'1001'"


  describe "Instance", ->
    statement = new SQLStatement "Select * from jacki where id = :id and name = :name",
      id    : Number
      name  : String


    it "can bind data to sql statement", ->
      (statement.bind id: 134, name: "Placek").should.equal "Select * from jacki where id = 134 and name = 'Placek'"

    it "params can be altered", ->
      ObjectId = (require "mongoose").Types.ObjectId
      statement.params.id = (value) -> "'#{ObjectId value}'"

      statement.sql = "Update jacki set name = :name where id = :id"
      
      (statement.bind id: "52a1fa69524d119416000004", name: "Łapserdak")
        .should.equal "Update jacki set name = 'Łapserdak' where id = '52a1fa69524d119416000004'"

    it "can be used for fancy things", ->
      statement.params.limit = (value) ->
        if (typeof value is "number") and value then "top #{value}" else ""

      statement.defaults.limit = 0

      statement.sql = "Select :limit * from jacki"
      (statement.bind limit: 32).should.equal "Select top 32 * from jacki"
      (statement.bind()).should.equal "Select  * from jacki"


