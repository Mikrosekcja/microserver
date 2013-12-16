# Subjects controller
# ===================


debug       = require "debug"
Controller  = require "../Controller"

$           = debug "microserver:controllers:subjects"

$ "Loading..."
module.exports = new Controller
  name    : "subjects"
  routes  :
    list    : "GET    /subjects"
    new     : "POST   /subjects"
    single  : "GET    /subjects/:subject_id"
    # update  : "PUT    /subjects/:subject_id"
    # remove  : "DELETE /subjects/:subject_id"
  actions:
    new     : (req, res) -> res.send "Not implemented"

  
    