module.exports = 
  suits: [
    year    : 2013
    index   : 1234
    # TODO: rest should be a collection of acts!
    # Or maybe the collection of acts act as entries in R20 - yes!
    date    : Date.parse "2013-05-23"
    summary : "Strony niniejszym zgodnie i świadomie oświadczają, że jak jakąś [...] pozwę, to będzie jechać na sprawę do Krakowa, bo tu właśnie mieszkam."
    parties : [
      subject   : 84082801539 # Subject is a corporation or natural person
      role      : "pozwany"
      attorneys : [
        67010212345
      ]
    ,
      subject   : 43455
      role      : "powód"
      attorneys : [
        70112254321
      ]
    ]
  ,
    year    : 2013
    index   : 4322
    # TODO: rest should be a collection of acts!
    # Or maybe the collection of acts act as entries in R20 - yes!
    date    : Date.parse "2013-05-23"
    summary : "Nie wolno zwracać towaru macanego. Towar macany należy do macanta i nie podlega zwrotowi." 
    parties : [
      subject   : 84082801539 # Subject is a corporation or natural person
      role      : "pozwany"
      attorneys : [
        67010212345
      ]
    ,
      subject   : 43455
      role      : "powód"
      attorneys : [
        70112254321
      ]
    ]

  ]

  subjects:
    84082801539 :
      type        : "natural person"
      name        :
        first       : "Tadeusz"
        last        : "Łazurski"
    67010212345 :
      type        : "natural person"
      title       : "radca prawny"
      name        :
        first       : "Quintus"
        last        : "Calarus"
    43455       :
      type        : "corporation"
      name        :
        first       : "Stowarzyszenie Towarzystwo Towarzyszy Towarzyszących Konsumentom w Kwidzyniu"
    70112254321 :
      type        : "natural person"
      name        :
        first       : "Kubuś"
        last        : "Fryzjerczyk"
