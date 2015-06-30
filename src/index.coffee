R = require "./View/R"
Model = require "./Model/Model"

# R.create "Tester",
#   render: ->
#     R.div {}, "hello"

# R.render(R.Tester(), document.body)


R.render(R.Outline({element: Model.Rectangle}), document.body)







