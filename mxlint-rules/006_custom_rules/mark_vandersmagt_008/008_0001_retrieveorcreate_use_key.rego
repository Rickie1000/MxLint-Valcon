# METADATA
# scope: package
# title: Incorrect RetrieveOrCreate pattern
# description: Reduce the amount of input parameters per microflow to improve maintainability and reuse. Setting only the key values in retrieve or create microflows is essential for maintaining your application. It stimulates reuse within the application and reduces complexity of creating objects by providing consistent creation of entities within the application. Required changes to the object are performed after the Retrieve or Create microflow to minimize the changes of a single attribute
# authors:
# - Mark van der Smagt
# custom:
#  category: Maintainability
#  rulename: RetrieveOrCreateUseKey
#  severity: HIGH
#  rulenumber: 008_0001
#  remediation: The created object must match the retrieved object. Every inputparameter must also be used in the retrieve. Every attribute that is queried on in the retrieve on must also be set in the create. Use only the key values as input parameters and use only these to retrieve AND create the object.
#  input: .*\.Microflows\$Microflow\.yaml
package app.mendix.domain_model.retrieveorcreate_use_key

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false

# Policy passes if no errors are found
allow if count(errors) == 0

# ---------------------------------------------------------
# Error: Retrieve does not use all input parameters
# ---------------------------------------------------------
errors contains err if {
  is_retrieve_or_create_microflow

  params := input_parameters
  retrieve := retrieve_assoc_vars | retrieve_xpath_vars

  count(params - retrieve) > 0

  err := sprintf("[%v, %v, %v] %v - Retrieve does not use all parameters (params: %v, retrieve: %v)",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      params,
      retrieve
    ]
  )
}

# ---------------------------------------------------------
# Error: Create/Change does not use all input parameters
# ---------------------------------------------------------
errors contains err if {
  is_retrieve_or_create_microflow

  params := input_parameters
  create := used_variables_in_create

  count(params - create) > 0

  err := sprintf("[%v, %v, %v] %v - Create/Change does not use all parameters (params: %v, create: %v)",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      params,
      create
    ]
  )
}

# ---------------------------------------------------------
# Error: Retrieve and Create use different entities
# ---------------------------------------------------------
errors contains err if {
  is_retrieve_or_create_microflow

  retrieve := database_retrieve_entity
  # Only apply if database retrieve is used to retrieve entities, we cannot check for retrieves over association
  count(retrieve) != 0
  create   := create_entity
  count(create - retrieve) > 0

  err := sprintf("[%v, %v, %v] %v - Retrieved and created object are not of the same entity (retrieve: %v, create: %v)",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      retrieve,
      create
    ]
  )
}

# ---------------------------------------------------------
# Error: Retrieve input parameters must be subset of Create/Change attributes
# ---------------------------------------------------------
errors contains err if {
  is_retrieve_or_create_microflow

  retrieve := retrieve_assoc_vars | retrieve_xpath_vars
  create   := used_variables_in_create

  # Check that every retrieve variable is also in create variables
  # Compute missing variables as a set comprehension
  count(retrieve - create) > 0
  
  # Only raise error if there are missing variables


  err := sprintf("[%v, %v, %v] %v - Retrieve variables must be a subset of Create/Change variables (retrieve: %v, create: %v)",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      retrieve,
      create
    ]
  )
}


# MICROFLOW TYPE DETECTION

# Detects "Retrieve...Create..." microflows based on naming
is_retrieve_or_create_microflow if {
  name := lower(input.Name)
  contains(name, "retrieve")
  contains(name, "create")
  indexof(name, "retrieve") < indexof(name, "create")
}

# RETRIEVE MICROFLOW INFORMATION

# Collects all input parameter names of the microflow
input_parameters := {p |
  o := microflow_objects[_]
  contains(lower(type_of(o)), "microflowparameter")
  p := o.Name
}

# Extracts all actions from action activities
actions := [a |
  action_activity := microflow_objects[_]
  action_activity["$Type"] == "Microflows$ActionActivity"

  a := object.get(action_activity, "Action", null)
  a != null
]


# Object collection helper
microflow_objects := objs if {
  objs := input.ObjectCollection.Objects
} else := [] if {
  true
}


# RETRIEVE VARIABLE USAGE

# Variables used in association-based retrieves
retrieve_assoc_vars := {v | 
  a := actions[_]

  action_type := object.get(a, "$Type", "")
  contains(lower(action_type), "retrieveaction")

  src := object.get(a, "RetrieveSource","")

  src_type := object.get(src, "$Type", "")
  contains(lower(src_type), "associationretrievesource")

  v := object.get(src, "StartVariableName", "")
  v != ""
}
  
# Variables used in database XPath retrieves
retrieve_xpath_vars := {v | 
  a := actions[_]

  action_type := object.get(a, "$Type", "")
  contains(lower(action_type), "retrieveaction")

  src := object.get(a, "RetrieveSource", null)
  src != null

  src_type := object.get(src, "$Type", "")
  contains(lower(src_type), "databaseretrievesource")

  xpath := object.get(src, "XpathConstraint", "")
  xpath != ""

  v := extract_xpath_vars(xpath)[_]
}

# CREATE / CHANGE VARIABLE USAGE

# Extract variables used in create/change actions
used_variables_in_create := vars if {
    vars_dollar := {vd |
        a := actions[_]

        action_type := object.get(a, "$Type", "")
        contains(lower(action_type), "changeaction")

        items := object.get(a, "Items", [])
        item := items[_]

        val := object.get(item, "Value", "")

        # Case 1: val starts with $, treat as variable
        startswith(val, "$")
        vd := trim_prefix(val, "$")

    } 
    vars_enum := {ve |
        a := actions[_]
        action_type := object.get(a, "$Type", "")
        contains(lower(action_type), "changeaction")

        items := object.get(a, "Items", [])
        item := items[_]

        val := object.get(item, "Value", "")

        # Case 2: val is a fully-qualified enum (contains ".")
        contains(val, ".")
        parts := split(val, ".")
        count(parts) > 0
        ve := parts[count(parts) - 1]  # Take last segment
    }
    vars := vars_dollar | vars_enum
}

# ENTITY EXTRACTION

# Extract entity used in retrieve
# ---------------------------------------------------------
# Extract entities used in all databaseretrieve actions
# AssociationRetrieveSource does not have entity information in metadata
# Returns a set of entity names
# ---------------------------------------------------------
database_retrieve_entity := {ent |
        a := actions[_]
        is_retrieve_action(a)

        src := object.get(a, "RetrieveSource", null)
        src != null

        src_type := object.get(src, "$Type", "")

        # -----------------------------
        # Case 1: DatabaseRetrieveSource
        # -----------------------------
        contains(lower(src_type), "databaseretrievesource")
        ent := object.get(src, "Entity", "")
        ent != ""
}

# Extract entity used in create/change
create_entity := { ent |
  a := actions[_]
  is_create_change_action(a)
  a != null
  ent := a.Entity
} 

# ACTION TYPE CHECKS

is_retrieve_action(a) if {
  contains(lower(type_of(a)), "retrieveaction")
}

is_create_change_action(a) if {
  contains(lower(type_of(a)), "changeaction")
}

# MATCH CHECK

# Checks if two sets are exactly equal
exact_match(a, b) if {
  a == b
}


# TYPE HELPER

# Safely extract $Type or $type
type_of(x) := t if {
  t := x["$Type"]
} else := t if {
  t := x["$type"]
} else := "" if {
  true
}

# XPATH VARIABLE EXTRACTION

# Extract all variables from XPath expression
# ---------------------------------------------------------
# Extract all variable and literal values from an XPath string
# Handles $variables and string literals ('...')
# Splits on [, ], AND, OR
# ---------------------------------------------------------
extract_xpath_vars(xpath) := vars if {
    # Step 1: normalize separators
    normalized := replace(replace(replace(replace(xpath, "[", " "), "]", " "), " AND ", " "), " OR ", " ")

    # Step 2: split on whitespace
    parts := split(normalized, " ")

    # Step 3: extract variables/literals
    vars_dollar := {vd |
        part := parts[_]
        trimmed := trim(part, " \t")
        trimmed != ""
        # case 1: variable starting with $
        startswith(trimmed, "$")
        vd := trim_prefix(trimmed, "$")
    } 
    vars_literal := {vl |
        part := parts[_]
        trimmed := trim(part, " \t")
        trimmed != ""
        # case 2: string literal in ''
        contains(trimmed, "'")
        vl := trim(trimmed, "'")
    }
    vars := vars_dollar | vars_literal
}

# ---------------------------------------------------------
# Get the last segment after the last dot
# e.g., "Mark_TESTING_MxLint.Gender.Male" -> "Male"
# ---------------------------------------------------------