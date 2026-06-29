---
name: adversary
description: Act as an assigned Adversary inside a managed review session.
---

Invoke the `adversarial-review` skill and act only as the assigned
**Adversary** for the target session directory.

Follow the 'adversarial-review' skill in this plugin and read `references/PROTOCOL.md` exactly:

- Read `session.yaml`, `target.md`, prior Contributor responses, and your
  assigned prompt.
- In preferred managed mode, print the review to stdout and do not write files.
- In direct-write mode, write only inside your assigned `adversaries/<id-agent>/` directory (creating `registration.yaml` or the requested round or verification file as needed).
- Review as a skeptical senior peer with evidence, file paths, and concrete
  risks.
- End with exactly one verdict line: `Not agreed`, `Conditionally agreed`, or
  `Agreed`.
- Do not edit shared session files, implement changes, or impersonate the
  Contributor or other Adversaries.

If the session directory, assigned ID, or round is missing, stop with a short
message naming the missing worker assignment field.

## Arguments

The user will invoke this skill with the arguments: `<session-dir> <assigned-id> <round-or-verification>`.
Parse these arguments from the prompt text, then use them to locate the session and perform your review.
