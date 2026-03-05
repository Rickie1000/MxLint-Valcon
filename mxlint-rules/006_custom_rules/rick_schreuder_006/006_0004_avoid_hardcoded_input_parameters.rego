# METADATA
# scope: package
# title: Avoid using hardcoded boolean switch input parameters
# description: Flags boolean microflow input parameters that are used in ExclusiveSplit expressions to steer control flow.
# authors:
# - Rick Schreuder
# custom:
#  category: Maintainability
#  rulename: AvoidHardcodedInputParameters
#  severity: MEDIUM
#  rulenumber: 006_0004
#  remediation: Prefer separate microflows or derive the decision inside the microflow rather than passing a boolean switch.
#  input: .*\.Microflows\$Microflow\.yaml

package app.custom.microflows.avoid_boolean_switch_input

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

errors contains err if {
  p := boolean_input_parameters[_]
  used_in_exclusive_split_expression(p.Name)

  err := sprintf(
    "[%v, %v, %v] %v - Boolean input parameter '%s' is used in an ExclusiveSplit expression (switch). Avoid hardcoded switch inputs.",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      p.Name
    ]
  )
}

# -----------------------------
# Model traversal (your exporter)
# -----------------------------
microflow_objects := objs if {
  objs := input.ObjectCollection.Objects
} else := objs if { objs := [] }

# -----------------------------
# Boolean input parameters (MicroflowParameter + BooleanType)
# -----------------------------
boolean_input_parameters := params if {
  objs := microflow_objects
  params := [p |
    p := objs[_]
    is_microflow_parameter(p)
    is_boolean_type(p.VariableType)
  ]
}

is_microflow_parameter(o) if {
  lower(type_of(o)) == lower("Microflows$MicroflowParameter")
} else if {
  # tolerate casing differences
  contains(lower(type_of(o)), "microflowparameter")
}

is_boolean_type(vt) if {
  vt != null
  contains(lower(type_of(vt)), "booleantype")
}

# -----------------------------
# Used as a switch if referenced in ExclusiveSplit.SplitCondition.Expression
# Example in your YAML:
#   $Type: Microflows$ExclusiveSplit
#   SplitCondition:
#     $Type: Microflows$ExpressionSplitCondition
#     Expression: $IsValid
# -----------------------------
used_in_exclusive_split_expression(param_name) if {
  s := microflow_objects[_]
  contains(lower(type_of(s)), "exclusivesplit")

  expr := s.SplitCondition.Expression
  is_string(expr)

  # match $ParamName usage (standard Mendix expression style)
  contains(expr, sprintf("$%s", [param_name]))
}

# -----------------------------
# Helpers
# -----------------------------
type_of(x) := t if { t := x["$Type"] } else := t if { t := x["$type"] } else := t if { t := "" }

is_string(x) if { sprintf("%T", [x]) == "string" }
