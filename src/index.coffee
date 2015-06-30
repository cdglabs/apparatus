R = require "./View/R"

R.create "Tester",
  render: ->
    R.div {}, "hello"

R.render(R.Tester(), document.body)
