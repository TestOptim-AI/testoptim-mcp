# Installing the TestOptim MCP server

These steps are for an AI assistant, such as Cline, setting up the TestOptim MCP server for a user.

TestOptim hosts the server, so there is nothing to install, build or run. Setup is one config entry with the endpoint URL and the user's API key.

- **Endpoint:** `https://api.testoptim.com/api/mcp`
- **Transport:** Streamable HTTP (`POST` only, stateless)
- **Auth:** header `Authorization: Bearer <TestOptim API key>` on every request

## 1. Get an API key from the user

Ask the user for a TestOptim API key. It starts with `topt_`. If they do not have one:

1. In TestOptim (https://www.testoptim.com), open **Settings**, then **API keys**, and select **New token**. Only the **Owner** or **Admin** role can create keys.
2. Choose **All projects** or one project, and keep the permissions they need:
   - `projects:read` for `list_projects` and `get_exploration`
   - `tests:run` for `start_test_run` and `stop_test_run`
   - `tests:read` for `get_test_run`
   - `issues:read` for `list_issues` and `get_issue`
   - `knowledge:explore` for `start_exploration`
3. Copy the token. TestOptim shows it only once.

Never write a real key anywhere except the user's local MCP settings file, and never commit it.

## 2. Add the server

For Cline, add this entry to `cline_mcp_settings.json`, replacing `topt_...` with the user's key:

```json
{
  "mcpServers": {
    "testoptim": {
      "type": "streamableHttp",
      "url": "https://api.testoptim.com/api/mcp",
      "headers": {
        "Authorization": "Bearer topt_..."
      },
      "disabled": false
    }
  }
}
```

Keep any servers already in the file.

## 3. Check it works

Call `list_projects`. It returns the projects the key can access, as JSON. If it fails:

- **401:** the key is missing, mistyped, revoked or expired, or the header is not `Authorization: Bearer topt_...`.
- **A tool is missing:** the key lacks that tool's permission (see step 1). The server lists only the tools the key can use.

## Next

See the [README](README.md) for every tool, example prompts, limits and troubleshooting.
