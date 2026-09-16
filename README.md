# KIT

KIT is a plugin for writing K specifications, proving them with Prover, and
independently auditing the results. This repository distributes the plugin
and the `kprover` CLI binaries.

## Install the plugin

Codex:

```bash
codex plugin marketplace add nlp-research-rosu/kit-plugin
codex plugin add kit@kit-plugin
```

Claude Code:

```bash
claude plugin marketplace add nlp-research-rosu/kit-plugin
claude plugin install kit@kit-plugin
```

Start a new agent session after installation.

## Install the CLI

macOS or Linux:

```bash
curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/nlp-research-rosu/kit-plugin/releases/latest/download/install-kprover.sh | sh
```

The installer selects your platform, verifies the SHA-256 checksum, installs
`kprover` in `~/.local/bin`, and adds it to your shell's PATH. Open a new terminal
after installation.

Windows PowerShell:

```powershell
Invoke-WebRequest `
  https://github.com/nlp-research-rosu/kit-plugin/releases/latest/download/install-kprover.ps1 `
  -OutFile install-kprover.ps1
& ./install-kprover.ps1
```

Open a new terminal after installation.

Check the installation:

```bash
kprover --version
kprover health
kprover semantics
```

No local K installation is required. Semantics sources download over HTTPS,
with Git fallback when repository credentials are needed.

## Use KIT

Ask your agent: `Use KIT to verify this program with the K framework.`

The plugin includes eight skills and their shared references: `using-kit`,
`kprover-setup`, `writing-spec`, `auditing-spec`, `proving-spec`,
`validating-proof`, `writing-semantics`, and `auditing-semantics`.
Verification requires Prover access.

## Updates

Refresh the marketplace and update the plugin:

```bash
codex plugin marketplace upgrade kit-plugin
codex plugin add kit@kit-plugin
```

```bash
claude plugin marketplace update kit-plugin
claude plugin update kit@kit-plugin
```

Run the latest release's installer to update the CLI, then start a new agent
session. Plugin and CLI versions are released together.
