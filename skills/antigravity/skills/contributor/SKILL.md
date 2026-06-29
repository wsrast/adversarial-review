---
name: contributor
description: Orchestrate a contributor-managed adversarial review session.
---

Invoke the `adversarial-review` skill and act as the **Contributor
orchestrator** for the target.

Follow the 'adversarial-review' skill in this plugin and read `references/PROTOCOL.md` exactly:

- Create or continue a review session under `~/dev/ao/reviews/<session>/`.
- Use autonomous continuation/goal mode when available so the human does not
  need to relay every round.
- Assign adversary IDs, create per-agent directories, and write prompts under
  `prompts/`.
- Invoke intended adversaries through available CLIs/integrations. Default to
  Claude and Codex when no adversaries are named and both are available.
- Do not invoke Antigravity as an Adversary when Antigravity is the
  Contributor. If Antigravity is named as an adversary, skip it with reason
  `same-as-contributor`.
- Keep `session.yaml` as Contributor-owned state. Do not ask adversaries to
  edit it.
- Wait for every adversary file in each round, then write the Contributor
  response.
- Implement only after agreement and required human/tool approvals.
- Request adversary verification after implementation.
- Close only after every adversary verifies with `Agreed`.

Ask a clarifying question only if the target is missing or the intended review
cannot be inferred safely.

## Arguments

The user will invoke this skill with the argument: `<target> [with <adversaries>]`.
Parse the target and any optional comma-separated adversaries from the prompt text, then use them to orchestrate the review.
