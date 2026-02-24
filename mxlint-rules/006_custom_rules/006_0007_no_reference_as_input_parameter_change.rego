# METADATA
# scope: package
# title: Do not use references in Change Object attribute values
# description: Prevent using reference expressions (e.g. $Obj/Assoc/Entity) inside Change Object (CreateChangeAction) attribute values.
# authors:
# - Rick Schreuder
# custom:
#   category: Maintainability
#   rulename: NoReferenceInChangeObjectValues
#   severity: MEDIUM
#   rulenumber: 006_0007
#   remediation: Retrieve the related object explicitly first, or use a direct object variable rather than reference paths.
#   input: "**/*$Microflow.yaml"

package app.custom.microflows.no_reference_in_change_object_values

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

errors contains error_message if {
  action_activity := input.ObjectCollection.Objects[_]
  action_activity["$Type"] == "Microflows$ActionActivity"

  create_or_change_action := action_activity.Action
  create_or_change_action["$Type"] == "Microflows$ChangeAction"

  # Heuristic: treat as "Change Object" when VariableName is empty OR when an object-variable field exists.
  created_variable_name := object.get(create_or_change_action, "VariableName", "")
  object_variable_name  := object.get(create_or_change_action, "ObjectVariableName", "")
  change_variable_name  := object.get(create_or_change_action, "ChangeVariableName", "")
  target_variable_name  := object.get(create_or_change_action, "Variable", "")

  is_change_object_action(create_or_change_action, created_variable_name, object_variable_name, change_variable_name, target_variable_name)

  entity_name := object.get(create_or_change_action, "Entity", "UnknownEntity")

  change_item := create_or_change_action.Items[_]
  change_item["$Type"] == "Microflows$ChangeActionItem"

  value_expression := object.get(change_item, "Value", "")
  is_string(value_expression)

  is_reference_path_expression(value_expression)

  attribute_name := object.get(change_item, "Attribute", "")

  error_message := sprintf(
    "[%v, %v, %v] Change Object (%v): reference path used in value for attribute '%v': %v",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      entity_name,
      attribute_name,
      value_expression
    ]
  )
}

# -----------------------------
# Helpers
# -----------------------------
is_reference_path_expression(expression) if {
  startswith(expression, "$")
  contains(expression, "/")
}

is_change_object_action(action, created_variable_name, object_variable_name, change_variable_name, target_variable_name) if {
  # Most common: no VariableName → not creating a new object
  created_variable_name == ""
} else if {
  # Some exports include explicit target variable fields for change object
  object_variable_name != ""
} else if {
  change_variable_name != ""
} else if {
  target_variable_name != ""
}
