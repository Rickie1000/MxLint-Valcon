# METADATA
# scope: package
# title: Use Refresh in Client sparingly (max 2 per microflow)
# description: Counts actions where RefreshInClient == true. Fails if more than 2 are present in a single microflow.
# authors:
# - Rick Schreuder
# custom:
#  category: Maintainability
#  rulename: ReduceRefreshInClient
#  severity: MEDIUM
#  rulenumber: 007_0003
#  remediation: Avoid excessive client refreshes; refresh once at the end or refresh only the minimum required objects.
#  input: '**/*$Microflow.yaml'

package app.custom.microflows.reduce_refresh_in_client

import rego.v1

annotation := rego.metadata.chain()[1].annotations

threshold := 2

default allow := false
allow if count(errors) == 0

errors contains err if {
  n := total_refresh_in_client_count
  n > threshold

  err := sprintf("[%v, %v, %v] %v (found %d > %d)",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      n,
      threshold
    ]
  )
}

# --------------------------------------------
# Total RefreshInClient=true actions in THIS microflow file:
# - Any ActionActivity where Action.RefreshInClient is true
# --------------------------------------------
total_refresh_in_client_count := n if {
  objs := microflow_objects

  refresh_actions := [1 |
    o := objs[_]
    is_action_activity(o)
    a := o.Action
    refresh_in_client_is_true(a)
  ]

  n := count(refresh_actions)
}

# Your exporter uses ObjectCollection.Objects
microflow_objects := objs if {
  objs := input.ObjectCollection.Objects
} else := objs if {
  objs := []
}

# ActionActivity node wrapper
is_action_activity(o) if {
  t := lower(type_of(o))
  contains(t, "actionactivity")
}

# $Type helper (your YAML uses $Type)
type_of(x) := t if {
  t := x["$Type"]
} else := t if {
  t := x["$type"]
} else := t if {
  t := ""
}

# RefreshInClient must be true (supports boolean true and string "true")
refresh_in_client_is_true(a) if {
  v := refresh_in_client_value(a)
  is_true_like(v)
}

refresh_in_client_value(a) := v if {
  v := a.RefreshInClient
} else := v if {
  v := a.refreshInClient
} else := v if {
  v := a.refresh_in_client
} else := v if {
  v := ""
}

is_true_like(v) if { v == true }
is_true_like(v) if {
  is_string(v)
  lower(v) == "true"
}