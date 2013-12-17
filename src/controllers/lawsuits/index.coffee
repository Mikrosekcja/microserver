# Lawsuits controller
# ===================

debug       = require "debug"
Controller  = require "../Controller"

$           = debug "microserver:controllers:lawsuits"

$ "Loading..."
module.exports = new Controller
  name    : "lawsuits"
  routes  :
    list    : 
      method  : "GET"
      url     : [
        "/lawsuits"
        "/lawsuits/:repository"
        "/lawsuits/:repository/:year"
      ]
    # new     : "POST   /lawsuits"
    single      : "GET    /lawsuits/:repository/:year/:number"
    update      : "PUT    /lawsuits/:repository/:year/:number"
    "add-party" : "POST   /lawsuits/:repository/:year/:number/parties"
    # remove  : "DELETE /lawsuits/:subject_id"
