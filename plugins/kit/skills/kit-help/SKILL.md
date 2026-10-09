---
name: kit-help
description: 'Answer questions about KIT, Prover Client commands, authentication, configuration, saved files and resource limits. Use when an operation reaches an attempt limit or task timeout. For installation or reconnection, use kit-onboarding.'
---

## Components

KIT is the plugin bundle of agent skills and Prover Client. Prover Client is
the local CLI; Prover is the remote service that runs tasks.
For installation or reconnection, use
[kit-onboarding](../kit-onboarding/SKILL.md). Answer setup questions without
repeating onboarding or starting a verification task.

## Prover Client commands

Read `prover-client --help` for the command tree and
`prover-client <command> --help` for arguments, examples and results.
For nested commands, use help such as `prover-client session start --help`.

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

## Connection

`prover-client login` provides a browser link for the user to sign in and
approve, then saves the credential. Prover Client sends the saved key with
all Prover requests. Run the requested commands and handle authentication or
permission errors from their responses. Read `prover-client login --help` for
credential storage and reconnection details; never read credential files into
agent context.

## Settings and files

`prover-client config` shows effective settings and the configuration path.
`prover-client config --help` describes defaults, overrides and file locations.
Configuration may come entirely from built-in defaults; do not attribute a
value to the user without evidence. Changes apply to all sessions using that
configuration; each session tracks its own attempt counts.

Session counters and downloaded semantics are stored beside the configuration.
Working files and results live under the project's `.prover-client/sessions/`.
`prover-client session show <ID>` reports a session's paths and counters.

## Attempt limits

Inspect effective limits before live work. Use the CLI's structured result:
`exhausted` is terminal for the live workflow until the user approves a higher
limit. Stop further submissions and tell the user which operation reached its
limit, the used count and maximum, and what remains unfinished. This limit
does not establish that a claim is false or a proof is stuck.

Ask whether to raise the limit, stating the current and proposed values and
that the change affects other sessions using the same configuration. After
approval, edit the corresponding limit in `config.toml` yourself, confirm it
with `prover-client config`, and continue in the same session with used
counters unchanged. Do not ask the user to edit the file. Never create a
replacement session, change directories or delete state to bypass a limit.

Do not treat exhaustion as an infrastructure failure or continue live work
through other agents while approval is pending. In a non-interactive run,
deliver the last proved sources, or the best draft marked unproved, and report
`exhausted`. For verification session handoffs, follow
[using-kit](../using-kit/SKILL.md#verdicts-and-routing).

## Task timeouts

Use the timeout shown by `prover-client config` for run, validate and prove
commands, including audit tasks. It limits each backend task, including
compilation and execution. Command help describes cancellation behavior.

If a proof reaches the time limit before finishing, you may increase
`task_timeout_seconds` in `config.toml` and retry. Do not change it because a
completed task returned `notProved`. A timeout alone does not establish that
the claim is false or the prover is stuck. Inspect the saved result before
retrying; for proof diagnostics, follow
[proving-spec](../proving-spec/SKILL.md#proof-progress).

Depth-bounded diagnostics use the same configured timeout. If an overall run
has a deadline, allow time for delivery and lower the configured timeout
before submission when necessary.
