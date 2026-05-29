---
description: Act as an assigned Adversary inside a managed review session.
argument-hint: <session-dir> <assigned-id> <round-or-verification>
---

Invoke the `$adversarial-review` skill and act only as the assigned
**Adversary** for:

$ARGUMENTS

Follow `~/.codex/skills/adversarial-review/SKILL.md` exactly:

- Read `session.yaml`, `target.md`, prior Contributor responses, and your
  assigned prompt.
- Write only inside your assigned `adversaries/<id-agent>/` directory.
- Create or update `registration.yaml` if needed.
- Write the requested round or verification file.
- Review as a skeptical senior peer with evidence, file paths, and concrete
  risks.
- End with exactly one verdict line: `Not agreed`, `Conditionally agreed`, or
  `Agreed`.
- Do not edit shared session files, implement changes, or impersonate the
  Contributor or other Adversaries.

If the session directory, assigned ID, or round is missing, ask for the missing
worker assignment before doing anything else.

