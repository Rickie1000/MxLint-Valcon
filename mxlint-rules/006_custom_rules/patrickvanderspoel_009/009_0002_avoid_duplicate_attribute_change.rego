# METADATA
# scope: package
# title: Avoid changing the same attribute multiple times in a microflow
# description: >
#   Each attribute on a specific object should be changed in as few places
#   as possible within a single microflow. When the same attribute on the
#   same object variable is set in multiple Change Object activities, it
#   creates duplication, makes the flow harder to maintain, and increases
#   noise in Find Usages / Find Changes. Instead, determine the value
#   using a variable or decision logic first, then set the attribute once
#   (or delegate to a submicroflow).
# authors:
# - Patrick (Valcon)
# custom:
#  category: Maintainability
#  rulename: AvoidDuplicateAttributeChange
#  severity: MEDIUM
#  rulenumber: 005_0012
#  remediation: >
#    Determine the value of the attribute using a variable (e.g. via an
#    exclusive split or expression), then set the attribute once using that
#    variable. Alternatively, extract the logic into a submicroflow.
#  input: .*\$Microflow\.yaml
package app.mendix.microflows.avoid_duplicate_attribute_change
import rego.v1

annotation := rego.metadata.chain()[1].annotations

# ============================================================
# Collect all (variable, attribute) pairs that are changed.
# We build a composite key "VariableName|Attribute" to track
# changes per object variable, not just per attribute type.
# ============================================================
all_variable_attribute_keys contains key if {
    some obj in input.ObjectCollection.Objects
    obj["$Type"] == "Microflows$ActionActivity"
    obj.Action["$Type"] == "Microflows$ChangeAction"
    some item in obj.Action.Items
    item["$Type"] == "Microflows$ChangeActionItem"
    item.Attribute != ""
    key := concat("|", [obj.Action.ChangeVariableName, item.Attribute])
}

# ============================================================
# Count how many separate ChangeAction activities modify a
# given (variable, attribute) combination.
# ============================================================
change_count_for_key(key) := count([1 |
    parts := split(key, "|")
    var_name := parts[0]
    attr_name := parts[1]
    some i, obj in input.ObjectCollection.Objects
    obj["$Type"] == "Microflows$ActionActivity"
    obj.Action["$Type"] == "Microflows$ChangeAction"
    obj.Action.ChangeVariableName == var_name
    some item in obj.Action.Items
    item["$Type"] == "Microflows$ChangeActionItem"
    item.Attribute == attr_name
])

# ============================================================
# Extract short attribute name for readable error messages
# "MyModule.Order.Status" -> "Order.Status"
# ============================================================
short_attr_name(qualified) := result if {
    parts := split(qualified, ".")
    count(parts) >= 3
    result := concat(".", array.slice(parts, 1, count(parts)))
}

short_attr_name(qualified) := qualified if {
    parts := split(qualified, ".")
    count(parts) < 3
}

# ============================================================
# DEFAULT
# ============================================================
default allow := false
allow if count(errors) == 0

# ============================================================
# ERROR: same attribute on same variable changed more than once
# ============================================================
errors contains error if {
    some key in all_variable_attribute_keys
    cnt := change_count_for_key(key)
    cnt > 1
    parts := split(key, "|")
    var_name := parts[0]
    attr_name := parts[1]
    error := sprintf("[%v, %v, %v] %v: '%v.%v' is changed in %v places in microflow '%v'. Use a variable to determine the value, then set the attribute once.",
        [
            annotation.custom.severity,
            annotation.custom.category,
            annotation.custom.rulenumber,
            annotation.title,
            var_name,
            short_attr_name(attr_name),
            cnt,
            input.Name,
        ]
    )
}
