---
name: prover-client-setup
description: 'Use when KIT cannot find the global Prover Client CLI or connect to Prover, or when the user asks to install or update it. Do not use for writing or proving K specifications.'
---

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

If both commands succeed, continue with the server checks. If the executable is
missing, or the user asks to update it, use the released installer below.

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

## Check Prover

Use the [command list](../shared/running-k.md#cli-contract) to inspect
configuration and check server health and the semantics
registry. Read the relevant command's `--help` for detailed usage.

If Prover requires authentication, run `prover-client login` and show the user
its
`verification_url`. The link includes the code; the user signs in and
approves. Keep the command running until it saves the key
and exits with `connected`, then retry the operation. Never ask for a key
in chat or read the CLI's
credential files. Read `prover-client login --help` for portal selection and
retrying
an expired connection.

Report an exact CLI error instead of falling back when a server check fails.
