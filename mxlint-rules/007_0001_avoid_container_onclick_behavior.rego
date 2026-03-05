# METADATA
# scope: package
# title: Avoid container on-click behavior.
# description: Gives a warning when on-click behavior is used on a container. Mendix does not inform screenreaders about clickable containers. Which it does do for listviews/datagrids/buttons/other clickable widgets.
# authors:
# - Lucas van Dongen
# custom:
#   category: Maintainability
#   rulename: AvoidContainerOnClickBehavior
#   severity: LOW
#   rulenumber: 007_0001
#   remediation: Incorporate visible buttons in your page design or instead of adding on click behavior on a container within a listview/gallery widget. Use the on-click action of the widget instead.
# input: ".*\\$Page\\.yaml$"

package app.custom.pages.avoid_container_onclick_behavior

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

# Walk the full YAML document and return every object node
nodes := [n |
  some p, n
  walk(input, [p, n])
  is_object(n)
]

errors contains error_message if {
  container := nodes[_]
  container["$Type"] == "Forms$DivContainer"

  on_click := object.get(container, "OnClickAction", null)
  on_click != null

  # Optional: only flag real actions (skip "no action" patterns if they appear)
  # If your YAML always has Forms$FormAction when set, keep this line.
  on_click_type := object.get(on_click, "$Type", "")
  on_click_type == "Forms$FormAction"

  error_message := sprintf(
    "[%v, %v, %v] On-click behavior detected on container (accessibility issue with screen readers). Name: %v",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      object.get(container, "Name", "<unknown container>")
    ]
  )
}