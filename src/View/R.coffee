React = require "react"
_ = require "underscore"

Model = require "../Model/Model"


module.exports = R = {}


# Provide easy access to React.DOM
for own key, value of React.DOM
  R[key] = value

# Utility (from React.addons.classSet)
R.cx = (classNames) ->
  Object.keys(classNames).filter((className) -> classNames[className]).join(" ")


R.create = (name, spec) ->
  # Component.displayName is used by React in its debugging messages.
  spec.displayName = name

  for typesProperty in ["propTypes", "childContextTypes", "contextTypes"]
    if spec[typesProperty]
      spec[typesProperty] = desugarPropTypes(spec[typesProperty])

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
    return React.PropTypes.instanceOf(propType).isRequired





R.DragManager = require "./Manager/DragManager"
R.HoverManager = require "./Manager/HoverManager"

require "./Generic/EditableText"
require "./Generic/HTMLCanvas"
require "./Picture"
require "./Editor"
require "./CreatePanel"
require "./Canvas"
require "./Outline"
require "./Inspector"
require "./AttributeRow"
require "./Expression"
