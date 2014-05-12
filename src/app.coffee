if not module.parent then do (require "source-map-support").install

express   = require "express"
_         = require "lodash"
async     = require "async"
mongoose  = require "mongoose" 
debug     = require "debug"

app       = express()
$         = debug "microserver"

pkg       = require "../package.json"
config    = require "../config"

engine    =
  name:     "Microserver"
  version:  pkg.version
  repo:     pkg.repository?.url

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
  # email   : do author[2]?.trim # Why advertise?
  website : do author[3]?.trim



app.use do express.favicon
app.use '/js',      express.static 'assets/scripts/app'
app.use '/scripts', express.static 'scripts' # Coffeescript sources for debug
app.use '/js',      express.static 'assets/scripts/vendor'

app.use '/css',     express.static 'assets/styles/app'
app.use '/css',     express.static 'assets/styles/vendor'

app.use do express.bodyParser
app.use do express.cookieParser
app.use express.session secret: (app.get "site")?.secret or "Zdradzę wam dzisiaj potworny sekret. Jestem ciasteczkowym potworem!"
app.use do express.methodOverride

app.use (req, res, next) ->
  # Set default values for res.locals
  res.locals
    # TODO: only engine is worth here. Rest can and should be left to view logic.
    title   : "Mikroserver"
    subtitle: "Mikrosekcja daje radę."
    icon    : "fighter-jet"
    engine  : engine

  do next

app.get "/", (req, res) -> res.redirect "/lawsuits"

lawsuits = require "./controllers/lawsuits"
lawsuits.plugInto app

subjects = require "./controllers/subjects"
subjects.plugInto app

mongourl = if config.mongo?.uri? then (Array config.mongo.uri).join "," else "mongodb://localhost/test"
mongoose.connect mongourl 
app.listen 31337