# METADATA
# scope: package
# title: Avoid create and delete buttons.
# description: Gives a warning when create or delete action buttons are used. Because these cannot be found by the "find usages in action" functionality when looking for delete or create actions of entities.
# authors:
# - Lucas van Dongen
# custom:
#  category: Maintainability
#  rulename: AvoidCreateDeleteButtons
#  severity: LOW
#  rulenumber: 007_0003
#  remediation: Replace create and delete buttons with custom microflows to ensure consistent behaviour the application.

package app.custom.pages.avoid_create_delete_buttons

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

# ------------------------------------------------------
# Scan full YAML document for create and delete buttons.
# ------------------------------------------------------

errors contains err if {
  button := action_buttons[_]

  action := object.get(button, "Action", null)
  action != null

  action_type := object.get(action, "$Type", "")
  action_type == "Forms$CreateObjectClientAction"

  err := sprintf("[%v, %v, %v] Create button detected (prefer custom actions for consistency). Name: %v",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      object.get(button, "Name", "")
    ]
  )
}

errors contains err if {
  button := action_buttons[_]

  action := object.get(button, "Action", null)
  action != null

  action_type := object.get(action, "$Type", "")
  action_type == "Forms$DeleteClientAction"

  err := sprintf("[%v, %v, %v] Delete button detected (prefer custom actions for consistency). Name: %v",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      object.get(button, "Name", "")
    ]
  )
}

nodes := [n |
  some p
  walk(input, [p, n])
  is_object(n)
]

action_buttons := [n |
  n := nodes[_]
  n["$Type"] == "Forms$ActionButton"
]