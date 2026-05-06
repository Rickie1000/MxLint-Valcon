# METADATA
# scope: package
# title: Do not place code/logic inside Change/Create Object value fields
# description: Prevent usage of if/then/else expressions inside Change Object / Create Object value fields. Logic must be implemented via microflow control.
# authors:
# - Rick Schreuder
# custom:
#   category: Maintainability
#   rulename: NoLogicInValueFields
#   severity: MEDIUM
#   rulenumber: 006_0006
#   remediation: Move logic to decisions (Exclusive split) and assign a variable, then use that variable as Value.
#   input: "**/*$Microflow.yaml"

package app.custom.microflows.no_logic_in_value_fields

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

###############################################################################
# MAIN: find Change/Create actions and scan their Items[].Value
###############################################################################

errors contains error_message if {

  microflow_object := input.ObjectCollection.Objects[_]
  microflow_object["$Type"] == "Microflows$ActionActivity"

  action := microflow_object.Action
  action_type := action["$Type"]

  # cover the variants seen in exports
  is_change_or_create_object_action(action_type)

  change_item := action.Items[_]
  value_expression := change_item.Value
  is_string(value_expression)

  contains_mendix_logic(value_expression)

  error_message := sprintf(
    "[%v, %v, %v] Logic detected inside value field (if/then/else). Attribute: %v. Value: %v",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      object.get(change_item, "Attribute", "<unknown attribute>"),
      value_expression
    ]
  )
}

###############################################################################
# HELPERS
###############################################################################

is_change_or_create_object_action(action_type) if {
  action_type == "Microflows$ChangeAction"
} else if {
  action_type == "Microflows$CreateChangeAction"
} else if {
  action_type == "Microflows$CreateObjectAction"
} else if {
  action_type == "Microflows$ChangeObjectAction"
}

# Detect Mendix logic inside a Value field (strict, low false positives)

# clear example of logic flow
contains_mendix_logic(value_expression) if {
  lower_value := lower(value_expression)
  padded_value := sprintf(" %s ", [lower_value])
  contains(padded_value, " if ")
  contains(padded_value, " then ")
  contains(padded_value, " else ")
}

# boolean and logic operators
contains_mendix_logic(value_expression) if {
  lower_value := lower(value_expression)
  padded_value := sprintf(" %s ", [lower_value])
  looks_like_expression(value_expression)
  contains_any_boolean_operator(padded_value)
  contains_any_boolean_condition_marker(padded_value)
}

# Requires mendix attribute otherwise and/or could return false positive
looks_like_expression(value_expression) if {
  contains(value_expression, "$")   # $currentUser, $Product, etc.
} else if {
  lower_value := lower(value_expression)
  regex.match("(?s).*[a-z_][a-z0-9_]*\\s*\\(.*\\).*", lower_value)
}

contains_any_boolean_operator(padded_value) if {
  contains(padded_value, " and ")
} else if {
  contains(padded_value, " or ")
} else if {
  contains(padded_value, " not ")
}

contains_any_boolean_condition_marker(padded_value) if {
  contains(padded_value, " = ")
} else if {
  contains(padded_value, " != ")
} else if {
  contains(padded_value, " >= ")
} else if {
  contains(padded_value, " <= ")
} else if {
  contains(padded_value, " > ")
} else if {
  contains(padded_value, " < ")
} else if {
  contains(padded_value, " contains()")
} else if {
  contains(padded_value, " startswith()")
} else if {
  contains(padded_value, " endswith()")
} else if {
  contains(padded_value, " isempty()")
} else if {
  contains(padded_value, " isnew()")
} else if {
  contains(padded_value, " not()")
} else if {
  contains(padded_value, " true ")
} else if {
  contains(padded_value, " false ")
}
