# Engram (MCP)

Repository-local **product spec** and **`REQ-*`** traceability (Makefiles, demos) are described in [Spec-driven development](SPEC-DRIVEN-DEVELOPMENT.md).

This repository versions [`.cursor/mcp.json`](../.cursor/mcp.json) so Cursor can use the **engram** MCP server:

```json
{
  "mcpServers": {
    "engram": {
      "command": "engram",
      "args": ["mcp"]
    }
  }
}
```

Install the `engram` CLI on your machine if you want this integration enabled. The bundle does not require Engram at runtime; it is optional tooling for maintainers and contributors using Cursor.
