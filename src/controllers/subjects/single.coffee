
module.exports = (req, res) ->
    async.waterfall [
      (done)          -> Subject.findById req.params.subject_id, done
      (subject, done) ->
        if not subject then throw Error "Not found"
        res.locals { subject }
        async.parallel
          attorney: (done) -> Lawsuit.find "parties.attorneys": subject._id, done
          party   : (done) -> Lawsuit.find "parties.subject"  : subject._id, done
          done
    ], (error, lawsuits) ->
      if error 
        if error.message is "Not found" then res.json error: "Not found"
        else throw error

      res.locals {lawsuits}
      console.dir res.locals
      res.json _.pick res.locals, [
        "subject"
        "lawsuits"
      ]

