const metadata = {
  scope: "package",
  title: "Use as few committing Create/Change Object actions as possible (max 2 per microflow)",
  description: "Counts CreateChangeAction with Commit != No and CommitAction objects. Fails if total > 2 in a microflow.",
  authors: ["Rick Schreuder"],
  custom: {
    category: "Maintainability",
    rulename: "ReduceCommits",
    severity: "MEDIUM",
    rulenumber: "006_0003",
    remediation: "Centralize persistence logic and avoid committing objects in many places.",
    // IMPORTANT: this is per-file, not whole-app
    input: ".*/*\\$Microflow\\.yaml"
  }
};

function rule(input = {}) {
  const errors = [];
  const threshold = 2;

  // In your export, actions live here:
  // input.ObjectCollection.Objects[*].Action.$Type
  const objs = input?.ObjectCollection?.Objects ?? [];

  let total = 0;

  for (const o of objs) {
    if (!o || typeof o !== "object") continue;

    const isActionActivity = o["$Type"] === "Microflows$ActionActivity";
    if (!isActionActivity) continue;

    const action = o.Action;
    if (!action || typeof action !== "object") continue;

    const t = action["$Type"];

    // Create/Change with commit enabled
    if (t === "Microflows$CreateChangeAction") {
      const commit = action.Commit; // e.g. "Yes", "YesWithoutEvents", "No"
      if (typeof commit === "string" && commit.toLowerCase() !== "no") {
        total += 1;
      }
    }

    // Commit Object action counts always
    if (t === "Microflows$CommitAction") {
      total += 1;
    }
  }

  if (total > threshold) {
    errors.push(
      `[${metadata.custom.severity}, ${metadata.custom.category}, ${metadata.custom.rulenumber}] ${metadata.title} (found ${total} > ${threshold})`
    );
  }

  return {
    allow: errors.length === 0,
    errors
  };
}

// // required export for mxlint
// module.exports = { metadata, rule };
