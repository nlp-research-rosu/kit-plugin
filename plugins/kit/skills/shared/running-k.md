# Running K through Prover

Use this reference to choose live K operations and apply KIT's evidence and
workflow rules. Detailed CLI usage lives in the executable's help.

## Shell setup

Live mode requires the global `prover-client` CLI and a reachable Prover server.
Locate the executable on `PATH`. If it is missing or KIT needs first-time
setup, use [kit-onboarding](../kit-onboarding/SKILL.md). Otherwise proceed with
the requested operation using the saved key. Handle authentication or
permission errors from the command response with
[kit-help](../kit-help/SKILL.md#connection).

## CLI contract

`prover-client` is the only live K client. For command usage, configuration
and resource limits, follow [kit-help](../kit-help/SKILL.md). Use its command
reference for `health` and `semantics` during setup. Use the CLI's structured
results for workflow decisions.

## Semantics descriptor

Start a session for the supplied language ID before live construction. Read
its help for project selection, shared source locations, and audit sessions.
The CLI owns the global `session.json`. Inspect its semantics ID and pinned
revision with `prover-client session show`. Use `prover-client semantics fetch`
to locate
the shared reference sources. Create `workspaceDir/inputs/` for session input
files: `spec.k`, `verification.k`, local dependencies, and concrete test
programs.
Keep reports, scripts, and operation results outside `inputs/`; the original
program stays in the project. Pass the session ID to each live command; command
help defines input paths. `prover-client run --program` takes a path relative to
the
session's project directory, not an absolute path.

For a clean-room audit, start another session for the same semantics ID and
confirm its semantics ID and commit match the construction session. A changed
server revision blocks that replay; do not silently audit different semantics.
Never manually replace the pin, edit downloaded sources, or upload bundled
semantics. If no
supported revision models the program language, the live pipeline is BLOCKED.

## Backends

Prover owns backend selection and definition reuse. For module or definition
mismatches, inspect the selected registry entry and submitted proof sources;
use the semantics and proof command help for diagnostic controls.

## Proof submission

Validate source structure before attempting proof. A successful validation is
not proof or non-vacuity evidence. For a failed proof, read the retained
evidence, repair the K artifacts, and submit in the same construction session.
Never use a prior task result as evidence for edited sources.

PyK APR accepts both `--depth` and `--trusted`. A trusted claim is
admitted without proof and is available to callers only through
`[depends(...)]`. A depth bound limits rewrite steps along each execution
path; a failing leaf yields `notProved`, while a bounded leaf without a
failure yields `inconclusive`. Remove `--depth` for the final positive proof.

Record assumed claims in the trust ledger under the
[soundness contract](proof-extension-soundness.md); command help explains how
to select claims and declare assumptions.

## Reading the result

Require `task.result.outcome` of `proved` and a final tool exit code of 0,
then inspect the submitted claim selection and saved stdout. PyK APR reports
`PROOF PASSED: <label>` for proved claims and `PROOF TRUSTED: <label>` for
admitted ones.
An admitted claim is an assumption, not a proved claim. Closure under the
supplied theory remains insufficient for validation; follow the proof audit
for soundness, adequacy, and non-vacuity.

The CLI saves the server's `/tasks/{id}/stdout` response as `stdout` in
`proof-NNN/result.json`. `task.result` has no residual field. When an APR
proof ends with unproved states, the last stdout line is
`RESIDUAL <KAST JSON>`; parse the KAST JSON after that prefix. It may combine
several failing, pending, or depth-bounded leaves, so it is not necessarily a
counterexample. Read stderr and the task result alongside stdout.

An internal exception from a prove task that validated cleanly is a failed
proof whose residual could not be printed, not a syntax problem. Do not bisect
the sources; check the claims' boundary cases and inspect a focused claim.

For a deliberate false postcondition, require `notProved` plus a residual
showing the unmet condition. An error or inconclusive result is not mutation
evidence. Account for every accepted submission: stopping the local process
does not by itself prove that its server task stopped.

## Diagnostic entry points

- Validate to separate source or module failures from proof behavior.
- Isolate claims and inspect bounded residuals when a proof stalls; see
  [bounded inspection](../proving-spec/SKILL.md#symptom-router-and-bounded-inspection).
- For task timeouts, follow [kit-help](../kit-help/SKILL.md#task-timeouts).

## Recording prove.sh

`prove.sh` is executable evidence, not a summary. It must call the global
`prover-client` CLI with the same session and controls used for the final run.
Retain
the associated task evidence. Never start a new session automatically inside
the script to bypass an attempt limit. Never reduce it to a process exit check,
and never use a depth bound in its final positive proof.
