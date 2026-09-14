---
name: using-kit
description: 'Use when asked to verify a program with the K framework — proving partial correctness, formalizing a language in K, writing K specs or proofs. Orchestrates the construction-and-audit pipeline via subagent dispatch, and routes one-off K questions to the owning skill.'
---

## What this kit proves

This kit proves **partial correctness**: if a program terminates and
its precondition holds, then its postcondition holds at termination.

`kprove` establishes reachability claims by symbolic execution. For a
loop, an invariant claim acts coinductively as a **circularity**: when
execution returns to a matching symbolic loop-head configuration, the
prover may apply that claim instead of unrolling the loop again.

Keep three activities distinct:

- **Verification** — `kprove` exits 0 and prints `#Top` under the
  supplied theory.
- **Soundness audit** — proof extensions genuinely describe the
  program and do not introduce execution-bypassing reasoning.
- **Validation** — theorem scope, non-vacuity, trust, and independent
  evidence support the intended property.

## Choose the execution path first

Live verification is the default. Load and run
[running-k.md — Shell setup](../shared/running-k.md#shell-setup),
which locates the global `kprover` CLI and probes server health. When it
succeeds, stay live and use only that CLI. If setup is incomplete, route to
`kprover-setup` before deciding Prover is unavailable. The agent host does not
call local K tools. If Prover remains unavailable, stop as BLOCKED
and report the exact error.

## Run the pipeline

Run construction, spec review, and repairs yourself using the stage skills.
Delegate only the final `validating-proof` audit to a fresh subagent when
available and permitted; otherwise use the inline fallback below.

At kickoff, settle the automation level: how hard to push before
stopping (rerolls, alternative attack angles at each defect). If the
initiating prompt states a level, use it. Otherwise ask the human.
If nobody can answer — a non-interactive run — assume maximum
automation and never wait on a reply.

Settle the prover task timeout the same way: if the initiating prompt
supplies one, use it; otherwise offer the human the option to set it,
hinting at times from prior runs when such data exists. Absent
guidance, choose generously yourself: the timeout bounds how long a
task may be waited on before stuck becomes a better explanation than
slow — it confines cost, never grades speed, so a healthy proof must
never be the thing it kills. State the timeout you chose in the
progress message, so the human sees the number before the run.

## The pipeline

```text
select bundled semantics -> writing-spec -> auditing-spec
                         -> proving-spec -> validating-proof -> PROOF.md
```

| Stage | Skill | Artifacts |
|---|---|---|
| Select the language | `using-kit` | Session ID with one pinned revision |
| State the theorem | `writing-spec` | `spec.k`, `VERIFICATION-SUMMARIES`, `SCOPE.md` |
| Audit the theorem | `auditing-spec` | `audits/spec-audit-<n>.md` |
| Close the proof | `proving-spec` | `VERIFICATION` extensions, `prove.sh`, `#Top` |
| Audit the proof | `validating-proof` | `audits/proof-audit-<n>.md`, `PROOF.md` |

Before construction, use the supplied semantics ID, or select the matching ID
from `kprover semantics`. Start the construction session and read its returned
sources with the agent harness. Follow
[running-k.md](../shared/running-k.md#semantics-descriptor)
for the shared selection contract; command help owns usage details.
If no ID matches, stop as BLOCKED. Live Kit never asks the user for semantics
files and never runs `writing-semantics` or `auditing-semantics`.

Dispatch the final audit without inherited conversation or construction
reasoning. Keep the candidate unchanged during the audit. Template:

> You are the validating-proof subagent of a K verification pipeline. Read
> <skill path> and follow it exactly, including its Dispatch
> contract. Your inputs are exactly these paths: <paths>. Produce the
> artifacts your skill names, then report back in the format its
> Dispatch contract states. Do not repair the candidate:
> the on-disk artifacts are your only evidence — never the
> constructor's report.

## Verdicts and routing

Every audit ends its review artifact with the block:

```text
VERDICT: PASS | FAIL | BLOCKED
TARGET: <stage>       (FAIL only)
REASON: <one sentence>
```

- **PASS** — continue to the next stage. A proof-audit PASS produces
  `PROOF.md`; if its status leaves the requested contract unmet, repair the
  reported gap within the remaining budget and repeat the affected checks.
- **FAIL** — the auditor proposes the earliest defective stage in
  TARGET. Review the evidence in the audit artifact; the routing
  decision is yours. Repair at the chosen stage using the audit
  artifact, then re-run every downstream stage and
  audit — an approved artifact built on a redone predecessor is
  approved no longer.
- **BLOCKED** — the auditor's instruments failed. That is an
  infrastructure problem, never evidence against the artifact: repair
  the environment and repeat the same audit; treat persistent
  BLOCKED as a hard-blocker candidate.

Start one bounded session before construction and reuse its ID for concrete
runs, validation, proofs, and every repair attempt. When its configured attempt
limit is exhausted, stop and ask the human for help; never create a replacement
session to bypass the limit.
The final proof audit uses its own clean-room workspace and session for
replay and negative probes, never for construction repairs or extra attempts.
When handing control back to the user, retain session IDs and evidence paths
in the report. New user feedback that
re-enters verification starts a fresh session with full budgets, even for the
same program; explanation-only questions create none. Returning from an audit
to construction is not a user handoff and does not reset construction budgets.
Rollbacks between pipeline stages still follow the
[soundness contract](../shared/proof-extension-soundness.md).

## Inline fallback

If subagent dispatch is unavailable or denied, run the same stage
contracts inline and sequentially. The audit rules do not relax:
write each stage's report to disk, then audit strictly from the
on-disk artifacts rather than relying on construction reasoning. Use this
fallback also when the harness cannot provide a fresh subagent context.
Record `same-agent review` in the audit and `PROOF.md` when using the fallback;
do not call it independent review. Fresh replay and negative probes remain
required in live mode.

## Router: one-off requests

For a question that is not a full pipeline run, route directly:

| Request | Open |
|---|---|
| Prepare a candidate semantics for a future Prover release | `writing-semantics` |
| State a theorem, derive an invariant or summary | `writing-spec`, [deriving-invariants.md](../shared/deriving-invariants.md) |
| Prove a spec's claims, or make a stuck proof pass | `proving-spec` |
| Judge a passing proof's honesty | `validating-proof` |
| Read a docstring-style contract precisely | [reading-the-contract.md](../shared/reading-the-contract.md) |
| K syntax, claims, build commands | [k-syntax.md](../shared/k-syntax.md), [k-claims.md](../shared/k-claims.md), [running-k.md](../shared/running-k.md) |

## Shared references

- [Proof-extension soundness contract](../shared/proof-extension-soundness.md)
  — the constitution: taxonomy, gates, statuses, repair doctrine.
- Gate obligations: [A](../shared/gate-a-soundness.md),
  [B](../shared/gate-b-adequacy.md), [C](../shared/gate-c-evidence.md).
