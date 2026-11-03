---
name: testoptim-qa
description: Run TestOptim AI QA tests on a web app and fix the bugs they find. Use when the user asks to QA-test, re-test or check a web app for bugs with TestOptim, or after you change pages or flows in an app that has a TestOptim project, to confirm the change works in a real browser before calling it done.
license: MIT
---

# TestOptim QA

TestOptim explores a web app in a real browser, keeps a suite of test cases for it, runs them, and files each bug it finds with steps to reproduce, the page URL and a screenshot. This skill lets you use that loop while you code: change the app, re-test what you changed, read the bugs, fix them, re-test.

## 1. Check the connection

Look for the TestOptim MCP tools (`list_projects`, `start_test_run`, `get_test_run`, `list_issues`, `get_issue`). If they are present, use them and go to step 2.

If they are missing, tell the user how to connect, then stop:

1. In TestOptim, open **Settings > API keys**, create a key, and copy it. It starts with `topt_` and is shown once.
2. Export it in the shell that starts the agent: `export TESTOPTIM_TOKEN="topt_..."`.
3. Add the server. For Claude Code:
   `claude mcp add --transport http testoptim https://api.testoptim.com/api/mcp --header "Authorization: Bearer ${TESTOPTIM_TOKEN}"`
   Other clients: https://github.com/TestOptim-AI/testoptim-mcp#connect-your-client
4. Restart the agent.

Never ask the user to paste the key into the chat, and never write it into a file you commit.

If the user prefers a terminal command, the `testoptim` CLI does the same run: `testoptim run --project <id> --changed /checkout`. It exits non-zero on a high or critical issue. Install: https://github.com/TestOptim-AI/testoptim-cli

## 2. Pick the project

Call `list_projects`. If there is one project, use it. If there are several, pick the one whose URL matches the app you are working on, or ask the user. Reuse the same project ID for the rest of the session.

## 3. Start a run

- After a code change, pass `changedAreas`: the URL paths or flow names you touched, such as `["/checkout", "/cart"]`. Take them from your diff. This re-tests only what changed and costs fewer executions.
- For a full check, leave `changedAreas` out to run the whole suite.
- Each run uses the user's plan executions. Tell the user what you are about to run before you call `start_test_run`.
- TestOptim tests the deployed app at the project's URL, not your local files. Make sure your change is deployed to that URL (a preview or staging deploy) first. For an app on localhost or a private network, the user runs `testoptim tunnel --project <id>`; see https://www.testoptim.com/docs/integrations/run-tests-on-a-private-network

## 4. Wait for the result

Runs take minutes. Call `get_test_run` about every 30 to 60 seconds until the status is `completed` or `failed`. Report progress to the user only when the step changes. If you started a run by mistake, call `stop_test_run`.

## 5. Read and fix the bugs

1. Call `list_issues` with the `testRunId` to get only what this run found. Start with `severity: "critical"`, then `"high"`.
2. Call `get_issue` for each one you will fix. Read the steps to reproduce, the expected and actual behaviour, and the page URL.
3. Find the cause in the code and fix it. Do not change the test or hide the symptom.
4. Deploy, then start a new run with the same `changedAreas` to confirm the fix.
5. Report what the run found, what you fixed, and anything left open, with the issue titles and severities.

Medium and low issues: list them for the user and fix them only if asked.

## New pages or flows

If you added a page or a flow that the suite does not know yet, ask the user before you call `start_exploration`. It spends the plan's page allowance and replaces an exploration already running. Poll `get_exploration`. If it shows `waiting_otp_ready` or `waiting_otp`, tell the user to enter the one-time code in the TestOptim app.

## Errors

| Error | What to do |
|---|---|
| `401 Missing API token` or `401 Invalid API token` | The key is not set or is wrong. Ask the user to fix `TESTOPTIM_TOKEN` and restart the agent. |
| A tool is missing | The key lacks that permission (for example `tests:run`). Ask the user for a key that has it. |
| Another job is already in progress | A project runs one job at a time. Wait for it with `get_test_run` or `get_exploration`, then try again. |
| `totalCases` is lower than expected | The run was trimmed to the executions left on the plan. Tell the user. |
