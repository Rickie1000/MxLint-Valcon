# METADATA
# scope: package
# title: Do not use default values on attributes
# description: Avoid default values because it introduces hidden logic that is hard to detect via "find changes".
# authors:
# - Rick Schreuder
# custom:
#  category: Maintainability
#  rulename: NoDefaultValue
#  severity: LOW
#  rulenumber: 006_0001
#  remediation: Remove the attribute default value and set it explicitly in logic where needed.
#  input: .*DomainModels\$DomainModel\.yaml

package app.mendix.domain_model.no_default_value

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

default_value_is_set(default_value) if {
  default_value != null
  not is_empty_string(default_value)
}

is_empty_string(value) if {
  is_string(value)
  value == ""
}

is_numeric_attribute_type(attribute_type_string) if {
  attribute_type_string == "DataTypes$IntegerType"
} else if {
  attribute_type_string == "DataTypes$DecimalType"
} else if {
  attribute_type_string == "DataTypes$FloatType"
} else if {
  attribute_type_string == "DataTypes$LongType"
}

# Allow ONLY the tooling default "0" for numeric attributes.
# Anything else (e.g., "1", "2", "0.1") should still be flagged.
allowed_default_value(attribute_type_string, default_value_string) if {
  is_numeric_attribute_type(attribute_type_string)
  default_value_string == "0"
}

errors contains error_message if {
  some entity_index
  some attribute_index

  domain_model_entity := input.Entities[entity_index]
  domain_model_attribute := domain_model_entity.Attributes[attribute_index]

  attribute_value_block := object.get(domain_model_attribute, "Value", {})
  attribute_default_value := object.get(attribute_value_block, "DefaultValue", null)

  default_value_is_set(attribute_default_value)

  attribute_type_block := object.get(domain_model_attribute, "Type", {})
  attribute_type_string := object.get(attribute_type_block, "$Type", "")

  # If it is NOT the allowed numeric tooling default ("0"), then it's a violation
  not allowed_default_value(attribute_type_string, attribute_default_value)

  error_message := sprintf(
    "[%v, %v, %v] %v.%v has a default value set",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      domain_model_entity.Name,
      domain_model_attribute.Name
    ]
  )
}
