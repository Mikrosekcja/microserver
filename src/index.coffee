models = {}

models[model] = require "./models/" + model for model in [
  "Lawsuit"
  "Subject"
] 

module.exports = {
  models
}
