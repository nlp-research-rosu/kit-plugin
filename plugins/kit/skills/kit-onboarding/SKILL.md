---
name: kit-onboarding
description: 'Set up KIT when Prover Client is missing or not connected, or when the user requests installation, an update or reconnection. Covers CLI installation, browser approval and initial settings. Reuse completed setup on subsequent tasks.'
---

## KIT onboarding

Complete setup once for this machine and Prover endpoint. A working CLI and
an accepted saved credential let subsequent KIT tasks proceed without repeating
onboarding. Use this skill when setup is missing or the user requests it.

The agent installs and connects the CLI; the user only needs to open the login
link, sign in and approve. Read
[KIT help](../kit-help/SKILL.md) when
answering questions about the components, settings or saved data.

## Detect the CLI

KIT requires `prover-client` on `PATH`.

On macOS or Linux, run:

```bash
command -v prover-client
prover-client --version
```

On Windows PowerShell, run:

```powershell
Get-Command prover-client
prover-client --version
```

If both commands succeed, continue with the connection step. If the executable
is missing, or the user asks to update it, use the released installer below.

On macOS or Linux, install or update with:

```bash
curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/nlp-research-rosu/kit-plugin/releases/latest/download/install-prover-client.sh | sh
```

On Windows PowerShell:

```powershell
Invoke-WebRequest `
  https://github.com/nlp-research-rosu/kit-plugin/releases/latest/download/install-prover-client.ps1 `
  -OutFile install-prover-client.ps1
& ./install-prover-client.ps1
```

The installers select the platform binary, verify its checksum and configure
PATH. Start a new terminal or agent session, or run the shell command printed
by the installer, then repeat the detection commands above.

## Connect to Prover

For first-time setup, run `prover-client login` and show the user its
`verification_url`. The user signs in and approves. Keep the command running
until it saves the key and exits with `connected`.

Once connected, run normal Prover commands with the saved key. If a command
returns an authentication or permission error, use that response to resolve
the connection; follow `prover-client login --help` when reconnection is
needed. Never ask for a key in chat or read credential files into context.
If login is denied, stop setup.

## Finish setup

Run `prover-client config` and briefly explain the effective proof, validation
and concrete-run attempt limits, the task timeout in human-readable units, and
the configuration path. Use `prover-client config --help` for default values.
Distinguish built-in defaults from configured overrides. Each session tracks
its own attempt counts; configuration changes apply to sessions using that
configuration. One accepted proof submission can contain several claims.

Confirm that KIT is ready and return to the user's task. Do not repeat this
introduction on subsequent KIT tasks unless settings change or the user asks.
