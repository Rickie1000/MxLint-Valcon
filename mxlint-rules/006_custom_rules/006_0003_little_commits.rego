# METADATA
# scope: package
# title: Use as few committing Create/Change Object actions as possible (max 2 per microflow)
# description: Counts Create/Change Object actions where Commit != No. Fails if more than 2 are present in a single microflow.
# authors:
# - Rick Schreuder
# custom:
#  category: Maintainability
#  rulename: ReduceCommits
#  severity: MEDIUM
#  rulenumber: 006_0003
#  remediation: Centralize persistence logic and avoid committing objects in many places.
#  input: '**/*$Microflow.yaml'

package app.custom.microflows.reduce_commits

import rego.v1

annotation := rego.metadata.chain()[1].annotations

threshold := 2

default allow := false
allow if count(errors) == 0

errors contains err if {
  n := total_commit_count
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

# -----------------------------
# Total commits in THIS microflow file:
# - CreateChangeAction where Commit != No  (Yes/YesWithoutEvents)
# - CommitAction (commit object)
# -----------------------------
total_commit_count := n if {
  objs := microflow_objects

  create_change_commits := [1 |
    o := objs[_]
    is_action_activity(o)
    a := o.Action
    is_create_change_action(a)
    commit_is_enabled(a)
  ]

  commit_actions := [1 |
    o := objs[_]
    is_action_activity(o)
    a := o.Action
    is_commit_action(a)
  ]

  n := count(create_change_commits) + count(commit_actions)
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

# Actions
is_create_change_action(a) if {
  t := lower(type_of(a))
  contains(t, "createchangeaction")
}

is_commit_action(a) if {
  t := lower(type_of(a))
  contains(t, "commitaction")
}

# $Type helper (your YAML uses $Type)
type_of(x) := t if {
  t := x["$Type"]
} else := t if {
  t := x["$type"]
} else := t if {
  t := ""
}

# Commit must be Yes / YesWithoutEvents, i.e., not No
commit_is_enabled(a) if {
  v := lower(commit_value(a))
  v != ""
  v != "no"
}

commit_value(a) := v if {
  v := a.Commit
} else := v if {
  v := a.commit
} else := v if {
  v := ""
}
