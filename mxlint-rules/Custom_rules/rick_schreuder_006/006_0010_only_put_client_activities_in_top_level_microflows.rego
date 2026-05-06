# METADATA
# scope: package
# title: Only put client activities in top level microflows
# description: Client activities should only be used in top level microflows directly accessed by a user. Allow them in OCH_, ACT_, NAV_ and URL_ flows, and allow validation feedback only in VAL_ flows.
# authors:
# - Rick Schreuder
# custom:
#  category: Reliability
#  rulename: OnlyPutClientActivitiesInTopLevelMicroflows
#  severity: MEDIUM
#  rulenumber: 006_0011
#  remediation: Move client interaction logic to a top level OCH_, ACT_, NAV_ or URL_ microflow. Only use validation feedback in VAL_ flows.
#  input: .*Microflows\$Microflow\.yaml

package app.mendix.microflows.only_put_client_activities_in_top_level_microflows

import rego.v1

annotation := rego.metadata.chain()[1].annotations

default allow := false
allow if count(errors) == 0

mf_name := object.get(input, "Name", "")

is_och_flow if {
  startswith(mf_name, "OCH_")
}

is_act_flow if {
  startswith(mf_name, "ACT_")
}

is_nav_flow if {
  startswith(mf_name, "NAV_")
}

is_url_flow if {
  startswith(mf_name, "URL_")
}

is_val_flow if {
  startswith(mf_name, "VAL_")
}

is_allowed_client_flow if {
  is_och_flow
}

is_allowed_client_flow if {
  is_act_flow
}

is_allowed_client_flow if {
  is_nav_flow
}

is_allowed_client_flow if {
  is_url_flow
}

action_type(obj) := t if {
  action := object.get(obj, "Action", null)
  action != null
  t := object.get(action, "$Type", "")
}

has_refresh_in_client(obj) if {
  action := object.get(obj, "Action", null)
  action != null
  object.get(action, "RefreshInClient", false) == true
}

is_show_message(obj) if {
  action_type(obj) == "Microflows$ShowMessageAction"
}

is_close_page(obj) if {
  action_type(obj) == "Microflows$CloseFormAction"
}

is_close_page(obj) if {
  action_type(obj) == "Microflows$ClosePageAction"
}

is_download_file(obj) if {
  action_type(obj) == "Microflows$DownloadFileAction"
}

is_show_page(obj) if {
  action_type(obj) == "Microflows$ShowFormAction"
}

is_show_page(obj) if {
  action_type(obj) == "Microflows$OpenFormAction"
}

is_validation_feedback(obj) if {
  action_type(obj) == "Microflows$ValidationFeedbackAction"
}

is_client_activity(obj) if {
  has_refresh_in_client(obj)
}

is_client_activity(obj) if {
  is_show_message(obj)
}

is_client_activity(obj) if {
  is_close_page(obj)
}

is_client_activity(obj) if {
  is_download_file(obj)
}

is_client_activity(obj) if {
  is_show_page(obj)
}

client_activity_label(obj) := "Refresh in client" if {
  has_refresh_in_client(obj)
} else := "Show message" if {
  is_show_message(obj)
} else := "Close page" if {
  is_close_page(obj)
} else := "Download file" if {
  is_download_file(obj)
} else := "Show page" if {
  is_show_page(obj)
} else := "Validation feedback" if {
  is_validation_feedback(obj)
} else := "Client activity"

errors contains error if {
  obj := input.ObjectCollection.Objects[_]
  is_validation_feedback(obj)
  not is_val_flow

  error := sprintf(
    "[%v, %v, %v] Microflow %v contains Validation feedback, which should only be used in VAL_ flows",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      mf_name
    ]
  )
}

errors contains error if {
  obj := input.ObjectCollection.Objects[_]
  is_client_activity(obj)
  not is_allowed_client_flow

  error := sprintf(
    "[%v, %v, %v] Microflow %v contains client activity '%v', which should only be used in OCH_, ACT_, NAV_ or URL_ flows",
    [
      annotation.custom.severity,
      annotation.custom.category,
      annotation.custom.rulenumber,
      mf_name,
      client_activity_label(obj)
    ]
  )
}