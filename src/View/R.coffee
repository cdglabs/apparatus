React = require "react"
_ = require "underscore"


module.exports = R = {}


# Provide easy access to React.DOM
for own key, value of React.DOM
  R[key] = value

# Utility (from React.addons.classSet)
R.cx = (classNames) ->
  Object.keys(classNames).filter((className) -> classNames[className]).join(" ")


R.create = (name, spec) ->
  if spec.propTypes
    spec.propTypes = desugarPropTypes(spec.propTypes)

  component = React.createClass(spec)
  R[name] = React.createFactory(component)


R.render = React.render


desugarPropTypes = (propTypes) ->
  return _.mapObject propTypes, desugarPropType

desugarPropType = (propType) ->
  if propType == Number
    return React.PropTypes.number.isRequired
  else if propType == String
    return React.PropTypes.string.isRequired
  else if propType == Boolean
    return React.PropTypes.bool.isRequired
  else if propType == Function
    return React.PropTypes.func.isRequired
  else if propType == Array
    return React.PropTypes.array.isRequired
  else if propType == Object
    return React.PropTypes.object.isRequired
  else if propType == "any"
    return React.PropTypes.any
  else if propType.isVariantOf?
    # Custom propType for dealing with Nodes
    return (props, propName, componentName) ->
      prop = props[propName]
      unless prop.isVariantOf(propType)
        return new Error("In `#{componentName}`, property `#{propName}` is the wrong type.")
  else
    return propType
