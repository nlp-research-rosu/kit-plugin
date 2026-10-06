# Running K through Prover

Use this reference to choose live K operations and apply KIT's evidence and
workflow rules. Detailed CLI usage lives in the executable's help.

## Shell setup

Live mode requires the global `prover-client` CLI and a reachable Prover server.
Locate the executable on `PATH`, check server health, and inspect the semantics
registry using the commands below. If setup is incomplete, use
[prover-client-setup](../prover-client-setup/SKILL.md), then retry.

Treat a failed health check as an infrastructure problem.

## CLI contract

`prover-client` is the only live K client. Read `prover-client --help` for the
command tree
and `prover-client <command> --help` for arguments, examples, settings, and
results.
For the nested session command, use `prover-client session start --help`.

| Command | When it helps |
|---|---|
| `prover-client config` | Inspect the endpoint and effective resource limits |
| `prover-client login` | Connect through the browser without exposing the API key |
| `prover-client health` | Check whether live verification is available |
| `prover-client semantics` | List server-supported language revisions |
| `prover-client semantics fetch` | Download shared semantics sources for inspection |
| `prover-client run` | Check the program's concrete behavior under that definition |
| `prover-client validate` | Catch source and module errors before proving |
| `prover-client session start` | Create a session and locate its working directory |
| `prover-client session show` | Inspect a session's pin, workspace, and used counters |
| `prover-client prove` | Submit a proof attempt or inspect a stuck claim |

Use the CLI's structured result for workflow decisions. `exhausted` is terminal
for the entire live KIT workflow until the user approves a higher limit.
Do not reinterpret it as BLOCKED or an instrument failure, and do not spawn or
continue agents or submit another live task while approval is pending.
In a non-interactive run, where nobody can answer, deliver the last proved
sources (or the best draft, marked unproved) and report `exhausted`.
Limit increases, session handoffs, and reset rules live in
[using-kit](../using-kit/SKILL.md#verdicts-and-routing).

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
confirm its repository and commit match the construction session. A changed
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

Do not start a replacement session, change directories, or delete state to
bypass a limit. Record assumed claims in the trust ledger under the
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
- Choose resource limits under the
  [resource caps](../proving-spec/SKILL.md#resource-caps) doctrine; a timeout is
  a diagnosis, not an automatic retry signal.

## Recording prove.sh

`prove.sh` is executable evidence, not a summary. It must call the global
`prover-client` CLI with the same session and controls used for the final run.
Retain
the associated task evidence. Never start a new session automatically inside
the script to bypass an attempt limit. Never reduce it to a process exit check,
and never use a depth bound in its final positive proof.
