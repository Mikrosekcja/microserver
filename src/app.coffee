if not module.parent then do (require "source-map-support").install

express   = require "express"
_         = require "lodash"
async     = require "async"
mongoose  = require "mongoose" 
debug     = require "debug"

app       = express()
$         = debug "microserver"

pkg       = require "../package.json"

engine    =
  name:     "Microserver"
  version:  pkg.version
  repo:     pkg.repo

author    = pkg.author.match ///
  ^
  \s*
  ([^<\(]+)     # name
  \s+
  (?:<(.*)>)?   # e-mail
  \s*
  (?:\((.*)\))? # website
  \s*
///
engine.author =
  name    : do author[1]?.trim
  email   : do author[2]?.trim
  website : do author[3]?.trim

app.use do express.favicon
app.use '/js', express.static 'assets/scripts/app'
app.use '/scripts', express.static 'scripts' # Coffeescript sources for debug
app.use '/js', express.static 'assets/scripts/vendor'

app.use '/css', express.static 'assets/styles/app'
app.use '/css', express.static 'assets/styles/vendor'

app.use do express.bodyParser
app.use do express.cookieParser
app.use express.session secret: (app.get "site")?.secret or "Zdradzę wam dzisiaj potworny sekret. Jestem ciasteczkowym potworem!"
app.use do express.methodOverride

app.use (req, res, next) ->
  # Set default values for res.locals
  res.locals
    title   : "Mikroserver"
    subtitle: "Mikrosekcja daje radę."
    icon    : "fighter-jet"
    engine  : engine

  do next

app.get "/", (req, res) -> res.redirect "/lawsuits"

lawsuits = require "./controllers/lawsuits"
app.get route, lawsuits.list for route in [
  "/lawsuits"
  "/lawsuits/:repository"
  "/lawsuits/:repository/:year"
]
app.get "/lawsuits/:repository/:year/:number", lawsuits.single
app.put "/lawsuits/:repository/:year/:number", lawsuits.update

subjects = require "./controllers/subjects"
subjects.plugInto app
# app.get "/subjects", subjects.list
# app.get "/subjects/:subject_id", subjects.single

mongoose.connect "mongodb://localhost/test"
app.listen 31337