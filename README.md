# KIT plugin

The KIT plugin bundles verification skills and the Prover Client CLI.
Prover Client connects to Prover, the remote server.

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

## Use KIT with your agent

Ask your agent:

```text
Use KIT to verify this function.
```

The agent checks for Prover Client and installs it if missing. If authentication
is needed, it gives you a browser link to sign in and approve the connection.
The client saves the credential and confirms the connection before the agent
continues.

The agent prepares the verification, submits it to Prover and audits the result.
It reports what was verified, any assumptions and anything still unresolved.

## Examples

[kit-examples](https://github.com/nlp-research-rosu/kit-examples) contains starting
verification challenges.

## Updates

Codex:

```bash
codex plugin marketplace upgrade kit-plugin
codex plugin add kit@kit-plugin
```

Claude Code:

```bash
claude plugin marketplace update kit-plugin
claude plugin update kit@kit-plugin
```

Start a new agent session and ask it to update Prover Client. Plugin updates
and CLI installation are separate operations.

## Manual CLI setup for developers

Use this section when running Prover Client directly or debugging an
integration. The agent handles setup in the normal plugin workflow.

### Install or update Prover Client

macOS or Linux:

```bash
curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/nlp-research-rosu/kit-plugin/releases/latest/download/install-prover-client.sh | sh
```

Windows PowerShell:

```powershell
Invoke-WebRequest `
  https://github.com/nlp-research-rosu/kit-plugin/releases/latest/download/install-prover-client.ps1 `
  -OutFile install-prover-client.ps1
& ./install-prover-client.ps1
```

The installer selects the platform binary, verifies its checksum and configures
PATH. Open a new terminal after installation.

### Check and connect

```bash
prover-client --version
prover-client health
prover-client semantics
prover-client login
```

`login` prints a browser link and waits for approval, then saves the key without
printing it. Health and language discovery checks do not establish that you
can submit authenticated tasks.

The production server and login portal are configured by default. Use
`prover-client config` to inspect settings and locate the configuration file.
Existing configuration, credentials and sessions remain in their `kprover`
directories after the executable rename. See `prover-client config --help` for
paths, task limits and cancellation behavior.

### Command reference

Replace angle-bracket placeholders with your language ID, session ID or project
path. A new session returns its ID and working directory. Keep proof input files
inside that directory's `inputs/` folder.

| Command | Purpose | Example |
| --- | --- | --- |
| `--version` | Show the installed client version | `prover-client --version` |
| `--help` | Show commands and options | `prover-client --help` |
| `help` | Show help for a command or subcommand | `prover-client help session start` |
| `login` | Sign in through the browser and save the credential | `prover-client login` |
| `config` | Show settings and the configuration file location | `prover-client config` |
| `health` | Check server availability | `prover-client health` |
| `semantics` | List supported language definitions | `prover-client semantics` |
| `semantics fetch` | Download sources for a supported language | `prover-client semantics fetch <SEMANTICS_ID>` |
| `session start` | Create a verification session with fresh attempt limits | `prover-client session start --project <PROJECT_PATH> --semantics <SEMANTICS_ID>` |
| `session show` | Inspect a session and its used attempt counters | `prover-client session show <SESSION_ID>` |
| `run` | Execute a concrete program for a supported language | `prover-client run --session <SESSION_ID> --program <PROGRAM_PATH>` |
| `validate` | Check verification inputs without proving them | `prover-client validate --session <SESSION_ID> --spec inputs/spec.k --spec-module SPEC` |
| `prove` | Submit a proof attempt and collect its result | `prover-client prove --session <SESSION_ID> --spec inputs/spec.k --spec-module SPEC` |

Use `prover-client <command> --help` for all arguments and result details.
`run --program` resolves paths from the project directory.
`validate` and `prove` resolve input paths from the session working directory.
Pass each additional input dependency with `--source`.
