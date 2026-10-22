# Contributing

This repository documents TestOptim's hosted MCP server. The server itself runs on TestOptim's infrastructure, so changes here are to the docs, the client configs and `server.json`.

Pull requests are welcome for:

- A client config that has changed format, or a new client that supports Streamable HTTP with custom headers. Please say which client version you tested with.
- Mistakes or unclear steps in the README.

Before opening a pull request:

- Never include a real API key, even a revoked one. Use `topt_...` as a placeholder.
- Keep `examples/*.json` valid JSON and in sync with the snippets in the README.
- If you change `server.json`, bump its `version`. CI validates it against the registry schema.

Bug reports about the server's behaviour, or questions about your account, go to [TestOptim support](https://www.testoptim.com/contact) rather than this repository's issues.
