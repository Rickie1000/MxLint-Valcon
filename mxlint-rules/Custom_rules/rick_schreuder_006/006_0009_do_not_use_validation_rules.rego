# METADATA
# scope: package
# title: Do not use validation rules
# description: Avoid entity validation rules; enforce validation via microflows for consistent maintainability.
# authors:
# - Rick Schreuder
# custom:
#  category: Maintainability
#  rulename: DoNotUseValidationRules
#  severity: MEDIUM
#  rulenumber: 006_0009
#  remediation: Remove entity validation rules and implement validation in a microflow.
#  input: .*DomainModels\$DomainModel\.yaml

package app.mendix.domain_model.do_not_use_validation_rules

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

is_array(x) if { type_name(x) == "array" }

errors contains error if {
  entity := input.Entities[_]

  vr := object.get(entity, "ValidationRules", null)
  is_array(vr)
  count(vr) > 0

  rule := vr[_]

  error := sprintf(
    "[%v, %v, %v] Entity %v uses validation rule on attribute %v (use microflow validation instead)",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      entity.Name,
      object.get(rule, "Attribute", "<unknown attribute>")
    ]
  )
}