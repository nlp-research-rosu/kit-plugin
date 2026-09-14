---
name: kprover-setup
description: 'Use when KIT cannot find the global kprover CLI or connect to Prover, or when the user asks to install or update it. Do not use for writing or proving K specifications.'
---

## Detect the CLI

KIT requires `kprover` on `PATH`.

On macOS or Linux, run:

```bash
command -v kprover
kprover --version
```

On Windows PowerShell, run:

```powershell
Get-Command kprover
kprover --version
```

If both commands succeed, continue with the server checks. If the executable is
missing, or the user asks to update it, use the released installer below.

On macOS or Linux, install or update with:

```bash
curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/nlp-research-rosu/kit-plugin/releases/latest/download/install-kprover.sh | sh
```

On Windows PowerShell:

```powershell
Invoke-WebRequest `
  https://github.com/nlp-research-rosu/kit-plugin/releases/latest/download/install-kprover.ps1 `
  -OutFile install-kprover.ps1
& ./install-kprover.ps1
```

The installers select the platform binary, verify its checksum and configure
PATH. Start a new terminal or agent session, or run the shell command printed
by the installer, then repeat the detection commands above.

## Check Prover

Use the [command list](../shared/running-k.md#cli-contract) to inspect
configuration and check server health and the semantics
registry. Read the relevant command's `--help` for detailed usage.

Report an exact CLI error instead of falling back when a server check fails.
