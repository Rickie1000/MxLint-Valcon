# METADATA
# scope: package
# title: Use less input parameters for microflows (max 5)
# description: Reduce the amount of input parameters per microflow to improve maintainability and reuse.
# authors:
# - Rick Schreuder
# custom:
#  category: Maintainability
#  rulename: MicroflowLimitInputParameters
#  severity: MEDIUM
#  rulenumber: 006_0002
#  remediation: Retrieve objects by association inside the flow. Reduce input to a main object and change values through associations.
#  input: .*\.Microflows\$Microflow\.yaml
package app.mendix.microflow.limit_input_parameters

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

max_params := 5

# ---- Extract microflow parameters from the exported YAML ----
# In Mendix export, input parameters are represented as objects with:
#   $Type: Microflows$MicroflowParameter
# inside ObjectCollection.Objects.
params := [o |
  objs := object.get(object.get(input, "ObjectCollection", {}), "Objects", [])
  o := objs[_]
  object.get(o, "$Type", "") == "Microflows$MicroflowParameter"
]

errors contains error if {
  count(params) > max_params

  mf_name := object.get(input, "Name", "Microflow (unknown name)")

  error := sprintf("[%v, %v, %v] Microflow '%v' has %v input parameters (max %v). Reduce inputs to improve reuse and traceability of data origin.",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      mf_name,
      count(params),
      max_params
    ]
  )
}
