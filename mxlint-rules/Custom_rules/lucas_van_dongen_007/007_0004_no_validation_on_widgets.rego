# METADATA
# scope: package
# title: Dp not use validation on a page.
# description: Always use microflows. Use entity when dealing with technical entities/attributes and masterdata. Never use page validation when direct user interaction is needed.
# authors:
# - Lucas van Dongen
# custom:
#  category: Maintainability
#  rulename: NoPageValidation
#  severity: LOW
#  rulenumber: 007_0004
#  remediation: Use microflow validation instead.

package app.custom.pages.avoid_widget_validation

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

# --------------------------------------------
# Detect widgets that use Validation with
# a non-empty Expression
# --------------------------------------------

errors contains err if {
  widget := widgets_with_validation[_]

  validation := object.get(widget, "Validation", null)
  validation != null

  validation_type := object.get(validation, "$Type", "")
  validation_type == "Forms$WidgetValidation"

  expr := validation_expression(validation)
  expr != ""

  err := sprintf("[%v, %v, %v] Widget validation detected (prefer microflow or server-side validation). Widget: %v",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      object.get(widget, "Name", "")
    ]
  )
}

nodes := [n |
  some p
  walk(input, [p, n])
  is_object(n)
]

widgets_with_validation := [n |
  n := nodes[_]
  object.get(n, "Validation", null) != null
]

validation_expression(v) := expr if {
  expr := object.get(v, "Expression", "")
} else := expr if {
  expr := object.get(v, "expression", "")
} else := expr if {
  expr := ""
}