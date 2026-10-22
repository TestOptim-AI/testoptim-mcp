#!/bin/sh
# Adds the TestOptim MCP server to Claude Code.
# Export your key first: export TESTOPTIM_TOKEN="topt_..."
: "${TESTOPTIM_TOKEN:?Export TESTOPTIM_TOKEN first}"

claude mcp add --transport http testoptim https://api.testoptim.com/api/mcp \
  --header "Authorization: Bearer ${TESTOPTIM_TOKEN}"
