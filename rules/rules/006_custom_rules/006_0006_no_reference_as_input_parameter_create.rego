# METADATA
# scope: package
# title: Do not use references in Create Object attribute values
# description: Prevent using reference expressions (e.g. $Obj/Assoc/Entity) inside Create Object (CreateChangeAction) attribute values.
# authors:
# - Rick Schreuder
# custom:
#   category: Maintainability
#   rulename: NoReferenceInCreateObjectValues
#   severity: MEDIUM
#   rulenumber: 006_0006
#   remediation: Retrieve the related object explicitly first, or pass the object directly, instead of using a reference path.
#   input: "**/*$Microflow.yaml"

package app.custom.microflows.no_reference_in_create_object_values

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

errors contains error_message if {
  action_activity := input.ObjectCollection.Objects[_]
  action_activity["$Type"] == "Microflows$ActionActivity"

  create_or_change_action := action_activity.Action
  create_or_change_action["$Type"] == "Microflows$CreateChangeAction"

  # Heuristic: treat as "Create Object" when Entity exists and VariableName exists.
  # (Adjust if your export provides explicit fields.)
  entity_name := object.get(create_or_change_action, "Entity", "")
  created_variable_name := object.get(create_or_change_action, "VariableName", "")

  entity_name != ""
  created_variable_name != ""

  change_item := create_or_change_action.Items[_]
  change_item["$Type"] == "Microflows$ChangeActionItem"

  value_expression := object.get(change_item, "Value", "")
  is_string(value_expression)

  is_reference_path_expression(value_expression)

  attribute_name := object.get(change_item, "Attribute", "")

  error_message := sprintf(
    "[%v, %v, %v] Create Object (%v): reference path used in value for attribute '%v': %v",
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
