# Running K through Prover

Use this reference to choose live K operations and apply KIT's evidence and
workflow rules. Detailed CLI usage lives in the executable's help.

## Shell setup

Live mode requires the global `kprover` CLI and a reachable Prover server.
Locate the executable on `PATH`, check server health, and inspect the semantics
registry using the commands below. If setup is incomplete, use
[kprover-setup](../kprover-setup/SKILL.md), then retry.

Treat a failed health check as an infrastructure problem. Never fall back to
local K commands in live mode.

## CLI contract

`kprover` is the only live K client. Read `kprover --help` for the command tree
and `kprover <command> --help` for arguments, examples, settings, and results.
For the nested session command, use `kprover session start --help`.

| Command | When it helps |
|---|---|
| `kprover config` | Inspect the endpoint and effective resource limits |
| `kprover health` | Check whether live verification is available |
| `kprover semantics` | List server-supported language revisions |
| `kprover semantics fetch` | Download shared semantics sources for inspection |
| `kprover run` | Check the program's concrete behavior under that definition |
| `kprover validate` | Catch source and module errors before proving |
| `kprover session start` | Create a session and locate its working directory |
| `kprover session show` | Inspect a session's pin, workspace, and used counters |
| `kprover prove` | Submit a proof attempt or inspect a stuck claim |

Use the CLI's structured result for workflow decisions. `exhausted` is terminal
for the entire live KIT workflow, not merely the current command or stage. Do
not reinterpret it as BLOCKED or an instrument failure, and do not spawn or
continue agents or submit another live task. Stop and ask the user for help.
Session handoff and reset rules live in
[using-kit](../using-kit/SKILL.md#verdicts-and-routing).

## Semantics descriptor

Start a session for the supplied language ID before live construction. Read
its help for project selection, shared source locations, and audit sessions.
The CLI owns the global `session.json`. Inspect its semantics ID and pinned
revision with `kprover session show`. Use `kprover semantics fetch` to locate
the shared reference sources. Create `workspaceDir/inputs/` for session input
files: `spec.k`, `verification.k`, local dependencies, and concrete test
programs.
Keep reports, scripts, and operation results outside `inputs/`; the original
program stays in the project. Pass the session ID to each live command; command
help defines input paths.

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

Do not start a replacement session, change directories, or delete state to
bypass a limit. Record assumed claims in the trust ledger under the
[soundness contract](proof-extension-soundness.md); command help explains how
to select claims and declare assumptions.

## Reading the result

A closed `#Top` under the supplied theory is necessary but insufficient for
validation. Follow the proof audit to establish soundness, adequacy, and
non-vacuity. Read the retained task result and logs together; command help
explains their fields and locations.

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
`kprover` CLI with the same session and controls used for the final run. Retain
the associated task evidence. Never start a new session automatically inside
the script to bypass an attempt limit. Never reduce it to a process exit check,
and never use a depth bound in its final positive proof.
