# METADATA
# scope: package
# title: Cast current user
# description: If there is a currentUser, it is already in context which makes a database call unneeded
# authors:
# - Mark van der Smagt
# custom:
#  category: Performance
#  rulename: CastCurrentUser
#  severity: MEDIUM
#  rulenumber: 008_0002
#  remediation: Retrieve the current user from context, if you need a specialisation, use a cast activity.
#  input: .*\.Microflows\$Microflow\.yaml
package app.mendix.domain_model.retrieveorcreate_use_key

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false

# Policy passes if no errors are found
allow if count(errors) == 0

# ---------------------------------------------------------
# Error: Retrieve currentUser from database
# ---------------------------------------------------------
errors contains err if {
  a := actions[_]
  is_retrieve_action(a)

  src := object.get(a, "RetrieveSource", null)
  src != null

  src_type := object.get(src, "$Type", "")
  contains(lower(src_type), "databaseretrievesource")

  xpath := object.get(src, "XpathConstraint", "")
  xpath != ""
  xpath_retrieves_currentUser(xpath)

  err := sprintf("[%v, %v, %v] %v - Retrieving currentUser via database is unnecessary (xpath: %v)",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      xpath
    ]
  )
}

is_retrieve_action(a) if {
  contains(lower(type_of(a)), "retrieveaction")
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

xpath_retrieves_currentUser(xpath) if {
  noWhitespace := replace(xpath, " ", "")
  contains(noWhitespace, "id=$currentUser")
}

xpath_retrieves_currentUser(xpath) if {
  noWhitespace := replace(xpath, " ", "")
  contains(noWhitespace, "$currentUser=id")
}

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
