debug       = require "debug"
Controller  = require "../Controller"

$           = debug "microserver:controllers:subjects"



module.exports = new Controller
  routes  :
    list    : "GET    /subjects"
    new     : "POST   /subjects"
    single  : "GET    /subjects/:subject_id"
    # update  : "PUT    /subjects/:subject_id"
    # remove  : "DELETE /subjects/:subject_id"
  actions:
    new     : (req, res) -> res.send "Not implemented"

  
    