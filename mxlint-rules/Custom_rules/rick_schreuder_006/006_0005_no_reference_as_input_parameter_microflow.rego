# METADATA
# scope: package
# title: Do not use references as microflow input parameters
# description: Prevent passing reference expressions (e.g. $Car/Association/Entity) as microflow input parameters.
# authors:
# - Rick Schreuder
# custom:
#   category: Maintainability
#   rulename: NoReferenceInputParametersMicroflow
#   severity: MEDIUM
#   rulenumber: 006_0005
#   remediation: Retrieve the related object explicitly before calling the microflow.
#   input: "**/*$Microflow.yaml"

package app.custom.microflows.no_reference_as_input_parameter

import rego.v1

# Load annotations (severity/category/rulenumber) from metadata.
annotation := rego.metadata.chain()[1].annotations

# MxLint expects allow to exist and be boolean.
default allow := false
allow if count(errors) == 0

errors contains error_message if {
  microflow_object := input.ObjectCollection.Objects[_]
  microflow_object["$Type"] == "Microflows$ActionActivity"

  action_in_activity := microflow_object.Action
  action_in_activity["$Type"] == "Microflows$MicroflowCallAction"

  microflow_call := action_in_activity.MicroflowCall
  parameter_mapping := microflow_call.ParameterMappings[_]

  argument_expression := parameter_mapping.Argument
  is_string(argument_expression)

  # Reference path pattern: starts with "$" and contains "/"
  startswith(argument_expression, "$")
  contains(argument_expression, "/")

  error_message := sprintf(
    "[%v, %v, %v] Reference expression used as microflow input parameter: %v",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      argument_expression
    ]
  )
}