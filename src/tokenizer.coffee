# # tokenizer

words = require "underscore.string.words"

module.exports = (query) ->
  subjects  = words prefix: "@", query
  if subjects
    subjects  = subjects.map (subject) -> subject.toLowerCase()
    query     = query.replace (new RegExp subject, "i"), "" for subject in subjects
  tokens     = words query
  tokens     = tokens?.map (token) -> token.toLowerCase()

  return {
    subjects
    tokens
  }
