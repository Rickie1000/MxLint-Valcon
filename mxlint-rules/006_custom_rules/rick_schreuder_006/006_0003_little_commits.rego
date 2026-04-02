# METADATA
# scope: package
# title: Use as few committing Create/Change Object actions as possible
# description: Counts Create/Change Object actions where Commit != No, plus Commit Object actions. Reports LOW for 1-2 commits, MEDIUM for 3-6, and HIGH for more than 6 commits.
# authors:
# - Rick Schreuder
# custom:
#  category: Maintainability
#  rulename: ReduceCommits
#  severity: LOW
#  rulenumber: 006_0003
#  remediation: Centralize persistence logic and avoid committing objects in many places.
#  input: .*\\$Microflow\.yaml

package app.custom.microflows.reduce_commits

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

# -----------------------------
# LOW: 1-2 commits
# -----------------------------
errors contains err if {
  n := total_commit_count
  n >= 1
  n <= 2

  err := sprintf("[%v, %v, %v] %v (found %d commits; consider reducing commits)",
    [
      "LOW",
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      n
    ]
  )
}

# -----------------------------
# MEDIUM: 3-6 commits
# -----------------------------
errors contains err if {
  n := total_commit_count
  n >= 3
  n <= 6

  err := sprintf("[%v, %v, %v] %v (found %d commits; too many commits)",
    [
      "MEDIUM",
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      n
    ]
  )
}

# -----------------------------
# HIGH: >6 commits
# -----------------------------
errors contains err if {
  n := total_commit_count
  n > 6

  err := sprintf("[%v, %v, %v] %v (found %d commits; excessive commits)",
    [
      "HIGH",
      annotation.custom.category,
      annotation.custom.rulenumber,
      annotation.title,
      n
    ]
  )
}

# -----------------------------
# Count commits
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

# -----------------------------
# Helpers
# -----------------------------
microflow_objects := objs if {
  objs := input.ObjectCollection.Objects
} else := objs if {
  objs := []
}

is_action_activity(o) if {
  t := lower(type_of(o))
  contains(t, "actionactivity")
}

is_create_change_action(a) if {
  t := lower(type_of(a))
  contains(t, "createchangeaction")
}

is_commit_action(a) if {
  t := lower(type_of(a))
  contains(t, "commitaction")
}

type_of(x) := t if {
  t := x["$Type"]
} else := t if {
  t := x["$type"]
} else := t if {
  t := ""
}

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