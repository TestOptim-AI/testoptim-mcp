<p align="center"><img src="assets/logo.png" alt="TestOptim" width="96" height="96"></p>

# TestOptim MCP server

Connect Claude Code, Cursor, VS Code and other MCP clients to [TestOptim](https://www.testoptim.com/), so your AI assistant can run QA tests on your web app and read the issues they find.

> "Run the QA suite on my project and show me the critical issues."

TestOptim hosts the server; there is nothing to install or run. This repository holds the setup instructions, ready-to-copy client configs, and the [`server.json`](server.json) that lists the server in MCP registries.

- **Endpoint:** `https://api.testoptim.com/api/mcp`
- **Transport:** Streamable HTTP (stateless; `POST` only)
- **Auth:** a TestOptim API key, sent as `Authorization: Bearer topt_...`

## Contents

- [Before you start](#before-you-start)
- [Create an API key](#create-an-api-key)
- [Connect your client](#connect-your-client)
- [Agent skill and Claude Code plugin](#agent-skill-and-claude-code-plugin)
- [Tools](#tools)
- [Example prompts](#example-prompts)
- [Security](#security)
- [Limits and errors](#limits-and-errors)
- [Troubleshooting](#troubleshooting)

## Before you start

- A TestOptim account with at least one project that has generated test cases. See [Generate test cases](https://www.testoptim.com/docs/test-cases/generate-test-cases).
- The **Owner** or **Admin** role in your organization, to create API keys.
- Runs started over MCP use your plan's test executions, the same as runs started in the app. They are attributed to the person who created the key.

## Create an API key

1. In TestOptim, open **Settings**, then **API keys**, and select **New token**.
2. Give it a name you will recognise, such as `Claude Code - laptop`.
3. Under **Project access**, choose **All projects** or a single project. A single project limits what a leaked key can reach.
4. Keep only the permissions you need (see [Tools](#tools) for which tool needs which).
5. Copy the token. It starts with `topt_` and is shown **once**.

Then export it in the shell your client starts from, so it never lands in a config file:

```bash
export TESTOPTIM_TOKEN="topt_..."
```

The full guide, with screenshots, is [Run TestOptim tests from CI with an API key](https://www.testoptim.com/docs/integrations/run-tests-from-ci-with-an-api-key).

To run tests from a GitHub Actions workflow instead, use [TestOptim Run Tests](https://github.com/TestOptim-AI/run-tests-action).

## Connect your client

Each snippet is also in [`examples/`](examples).

### Claude Code

```bash
claude mcp add --transport http testoptim https://api.testoptim.com/api/mcp \
  --header "Authorization: Bearer ${TESTOPTIM_TOKEN}"
```

This stores the token in your local Claude Code config. Add `--scope user` to use it in every project.

To share the server with your team without sharing a token, commit a project `.mcp.json` instead. Claude Code expands `${TESTOPTIM_TOKEN}` from each person's environment ([`examples/claude-code.mcp.json`](examples/claude-code.mcp.json)):

```json
{
  "mcpServers": {
    "testoptim": {
      "type": "http",
      "url": "https://api.testoptim.com/api/mcp",
      "headers": {
        "Authorization": "Bearer ${TESTOPTIM_TOKEN}"
      }
    }
  }
}
```

### Cursor

Add to `~/.cursor/mcp.json`, or `.cursor/mcp.json` in your project ([`examples/cursor.mcp.json`](examples/cursor.mcp.json)):

```json
{
  "mcpServers": {
    "testoptim": {
      "url": "https://api.testoptim.com/api/mcp",
      "headers": {
        "Authorization": "Bearer ${env:TESTOPTIM_TOKEN}"
      }
    }
  }
}
```

Cursor reads `TESTOPTIM_TOKEN` from your shell or system environment; remote servers don't support `envFile`.

### VS Code

Add to `.vscode/mcp.json` in your workspace, or run **MCP: Open User Configuration** for every workspace ([`examples/vscode.mcp.json`](examples/vscode.mcp.json)). VS Code asks for the key the first time the server starts and stores it securely:

```json
{
  "inputs": [
    {
      "type": "promptString",
      "id": "testoptim-token",
      "description": "TestOptim API key (starts with topt_)",
      "password": true
    }
  ],
  "servers": {
    "testoptim": {
      "type": "http",
      "url": "https://api.testoptim.com/api/mcp",
      "headers": {
        "Authorization": "Bearer ${input:testoptim-token}"
      }
    }
  }
}
```

### Windsurf

Add to your MCP config file (open it from Cascade's MCP settings). Remote servers use `serverUrl` ([`examples/windsurf.mcp_config.json`](examples/windsurf.mcp_config.json)):

```json
{
  "mcpServers": {
    "testoptim": {
      "serverUrl": "https://api.testoptim.com/api/mcp",
      "headers": {
        "Authorization": "Bearer ${env:TESTOPTIM_TOKEN}"
      }
    }
  }
}
```

### Claude (claude.ai and Claude Desktop)

Add TestOptim as a custom connector:

1. Open **Customize** > **Connectors**, select **+ Add**, then **Add custom connector**.
2. Name it `TestOptim` and enter `https://api.testoptim.com/api/mcp` as the server URL.
3. Under **Authentication**, choose **No sign in**.
4. Under **Request headers**, add `Authorization` with the value `Bearer topt_...` (your key).
5. Select **Add**.

On Team and Enterprise plans an Owner adds it under **Organization settings** > **Connectors**, and **everyone who uses the connector shares that one key**. Use a key limited to one project, and leave out `tests:run` unless every member should be able to start runs. Claude's Research mode can call connector tools without asking first, which is another reason to keep write permissions off a shared key. To change the key later, remove the connector and add it again.

### Other clients

Any client that supports Streamable HTTP with custom headers works. Point it at `https://api.testoptim.com/api/mcp` and send `Authorization: Bearer <your key>` on every request. The server is stateless: it doesn't issue session IDs, and it answers `GET` and `DELETE` with `405`.

## Agent skill and Claude Code plugin

The [`testoptim-qa`](skills/testoptim-qa/SKILL.md) skill teaches your coding agent the loop: after it changes a page or flow, it re-tests only that area, reads the critical and high issues, fixes them and re-tests. It follows the open [Agent Skills](https://agentskills.io) format, so it works in Claude Code, Codex, Cursor, Copilot and other agents that read `SKILL.md`. Export `TESTOPTIM_TOKEN` first (see [Create an API key](#create-an-api-key)).

### Claude Code plugin

The plugin installs the skill and connects the MCP server in one step:

```
/plugin install testoptim --marketplace TestOptim-AI/testoptim-mcp
```

On Claude Code older than 2.1.275, add the marketplace first:

```
/plugin marketplace add TestOptim-AI/testoptim-mcp
/plugin install testoptim@testoptim
```

### Other agents

Install the skill with the [`skills`](https://skills.sh) CLI, then connect the MCP server as shown in [Connect your client](#connect-your-client):

```bash
npx skills add TestOptim-AI/testoptim-mcp
```

## Tools

The server only lists the tools your key's permissions allow, so a read-only key never sees `start_test_run`.

| Tool | Permission | What it does | Arguments |
|---|---|---|---|
| `list_projects` | `projects:read` | Lists the projects the key can access, to find the project ID the other tools need. | none |
| `start_test_run` | `tests:run` | Starts a test run and returns the run ID. Pass `changedAreas` to re-test only the pages or flows you just changed; leave it out for the whole suite. Runs take minutes. | `projectId`, `changedAreas` (e.g. `["/checkout", "/cart"]`; optional) |
| `get_test_run` | `tests:read` | Shows a run's status (`pending`, `running`, `completed`, `failed`), progress, current step and issue counts by severity. | `testRunId` |
| `stop_test_run` | `tests:run` | Stops a running test run, so no further test cases are executed and billed. A stopped run reports as `failed`. | `testRunId` |
| `list_issues` | `issues:read` | Lists a project's issues as summaries: ID, title, severity, category, status. Pass `testRunId` for only what one run found. | `projectId`, `severity` (`critical`, `high`, `medium` or `low`; optional), `testRunId` (optional), `limit` (1-100, default 20) |
| `get_issue` | `issues:read` | Gets one issue in full: description, steps to reproduce, expected and actual behaviour, page URL and screenshot. | `issueId` |
| `start_exploration` | `knowledge:explore` | Explores the project's app so TestOptim learns new or changed pages and flows. Spends the plan's page allowance and replaces an exploration already running. Returns an exploration ID. | `projectId` |
| `get_exploration` | `projects:read` | Shows an exploration's status, progress and, once it ends, how many pages, flows and entities it recorded. `waiting_otp_ready` or `waiting_otp` means the login needs a one-time code entered in the TestOptim app. | `explorationId` |

Results come back as JSON text, using the same field names as the [TestOptim API](https://www.testoptim.com/docs/integrations/run-tests-from-ci-with-an-api-key).

## Example prompts

- "Which TestOptim projects can I access?"
- "Run the QA suite on the checkout project and tell me when it's done."
- "List the critical and high issues on my project, then show the steps to reproduce the first one."
- "I just changed the signup form. Run the tests, and if anything fails, open the issue and fix the code."
- "I changed /checkout. Re-test only that with TestOptim and fix any critical issues."
- "I added a settings page. Explore the app again so TestOptim picks it up."
- "Stop the test run you started; it's on the wrong project."

## Security

- **Least privilege.** Create a separate key per client and per machine, limited to one project and to the permissions it needs. A key without `tests:run` can't start or stop runs.
- **Project-scoped keys** are refused for any other project, and tools never show another organization's data.
- **Keep keys out of files you commit.** Use the environment-variable or input-prompt forms above. Keys start with `topt_`, so they are easy to search for in logs and repositories.
- **Revoke** a key under **Settings** > **API keys** if it leaks or a device is lost. It stops working immediately.
- An assistant connected with `tests:run` can start runs that use your plan's test executions. Most clients ask before calling a tool; keep that confirmation on.

## Limits and errors

- 120 requests per minute per client IP address, shared with the TestOptim REST API.
- A project runs one job at a time. Starting a run while another job is in progress on the same project is refused; wait for it to finish and try again.
- Like **Run all** in the app, a run is trimmed to your remaining test executions. Check `totalCases` on the run if you need the full suite.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `401 Missing API token` | The `Authorization` header didn't arrive. Check the environment variable is set in the shell that starts your client, then restart the client. |
| `401 Invalid API token` | The key is wrong, revoked or expired. Create a new one. |
| A tool you expect is missing | The key lacks that tool's permission. Create a key with it. |
| `This token is restricted to a different project` | The key is scoped to one project; use that project's ID or a key for all projects. |
| `405 Method not allowed` | Something sent a `GET` or `DELETE`. The server only accepts `POST`; use a client with Streamable HTTP support. |

## Contributing

Spotted an outdated client config, or want to add one for another client? See [CONTRIBUTING.md](CONTRIBUTING.md). For problems with your account or the TestOptim service itself, contact [TestOptim support](https://www.testoptim.com/contact) instead.

## License

[MIT](LICENSE)
