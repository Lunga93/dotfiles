# OpenCode

AI coding agent configuration with plugins, tools, and MCP servers.

## Location

`opencode/.config/opencode/` → `~/.config/opencode/`

## Key Files

| File | Purpose |
|------|---------|
| `opencode.jsonc` | MCP servers, plugins, theme |
| `tui.json` | TUI theme ("manatee") |
| `agent/image-reader.md` | Subagent for vision/image analysis |
| `plugins/vision-helper.ts` | Plugin that routes image analysis to subagent |
| `tools/vision.ts` | Vision tool definition |

## MCP Servers

| Server | Type | URL/Command | Status |
|--------|------|-------------|--------|
| `composio` | Remote | `https://connect.composio.dev/mcp` | Enabled |
| `openrouter_image` | Local | `npx openrouter-image-mcp` | Enabled |
| `writekit` | Remote | `http://127.0.0.1:8787/mcp` | Disabled (start WriteKit first) |

## WriteKit Integration

[WriteKit](https://github.com/Macawls/writekit) is an MCP-native documentation platform. It provides tools for creating, publishing, and managing markdown pages and collections through your AI assistant.

### Setup

```bash
# Build deps (Arch)
sudo pacman -S gtk3 webkit2gtk-4.1

# Install Wails
go install github.com/wailsapp/wails/v2/cmd/wails@latest

# Clone and run
git clone https://github.com/Macawls/writekit ~/src/writekit
cd ~/src/writekit/desktop && wails dev
```

The desktop app exposes a loopback MCP server at `http://127.0.0.1:8787/mcp`. The tray menu has a "Copy MCP URL" item.

### Usage

Once WriteKit is running and the MCP config is stowed:
1. OpenCode will connect to WriteKit's MCP server
2. Your AI assistant gains tools like `create_page`, `publish_page`, `list_pages`, `search_pages`, `create_collection`, etc.
3. All content lives in a local SQLite database

### Future: Public Deployment

WriteKit supports self-hosting with a domain for public access (see [writekit.dev](https://writekit.dev)). Requires a VPS or Cloudflare Tunnel + domain.

## Integration Points

- `opencode.jsonc` → MCP server definitions
- `~/.config/opencode/opencode.jsonc` → active config (stowed from this package)
- WriteKit MCP tools available as OpenCode tools when server is running
