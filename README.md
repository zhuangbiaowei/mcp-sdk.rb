# MCP SDK for Ruby

[![Gem Version](https://badge.fury.io/rb/mcp-sdk.rb.svg)](https://badge.fury.io/rb/mcp-sdk.rb)

A Ruby implementation of the Model Context Protocol (MCP) for both connecting to MCP servers and creating MCP servers.

## Features

- **Client Support**: Connect to SSE (Server-Sent Events) and Stdio-based MCP servers
- **Server Support**: Create MCP servers with tool registration
- Type-safe client interfaces  
- Easy integration with Ruby applications
- Comprehensive error handling
- JSON-RPC 2.0 compliant

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mcp-sdk.rb'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install mcp-sdk.rb
```

## Usage

### MCP Client

#### Connecting to an SSE-based MCP server

```ruby
require 'mcp-sdk.rb'
client = MCP::SSEClient.new('http://example.com/sse?key=api_key')
client.start
mcp_server_json = client.list_tools
puts JSON.pretty_generate(convertFormat(mcp_server_json))
```

#### Connecting to a Stdio-based MCP server

```ruby
require 'mcp-sdk.rb'

client = MCP::StdioClient.new('nodejs path/to/server_executable.js')
client.start
mcp_server_json = client.list_tools
puts JSON.pretty_generate(convertFormat(mcp_server_json))
```

### MCP Server

#### Creating an MCP Server

**Stdio Server (Default)**
```ruby
require 'mcp-sdk.rb'

# Create stdio server (processes JSON-RPC over stdin/stdout)
server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "stdio"  # optional, this is the default
)

# Add an addition tool
server.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

# Start the server (listens on stdin, responds on stdout)
server.start
```

**SSE Server (HTTP with Server-Sent Events)**
```ruby
require 'mcp-sdk.rb'

# Create SSE server (HTTP server with SSE support)
server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "sse",
  port: 8080
)

# Add tools as needed
server.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

server.add_tool("multiply") do |params|
  result = params["x"] * params["y"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

server.add_tool("greet") do |params|
  name = params["name"] || "World"
  {
    content: [{ type: "text", text: "Hello, #{name}!" }]
  }
end

# Start the HTTP server
server.start
```

#### Server Types

**Stdio Server (`type: "stdio"`)**
- Default server type
- Communicates via stdin/stdout using JSON-RPC 2.0
- Perfect for command-line tools and process-based communication
- No additional configuration required

**SSE Server (`type: "sse"`)**
- HTTP server with Server-Sent Events support
- Requires `port` parameter
- Provides REST endpoints and real-time SSE communication
- Includes CORS support for web applications

#### SSE Server Endpoints

When running an SSE server, the following HTTP endpoints are available:

- `GET /sse` - Server-Sent Events endpoint for real-time communication
- `POST /mcp` - JSON-RPC endpoint for tool calls
- `GET /tools` - List available tools (convenience endpoint)
- `GET /health` - Server health check

#### Server API

- `MCP::Server.new(name:, version:, type:, port:)` - Create a new server instance
  - `name`: Server name (required)
  - `version`: Server version (required)  
  - `type`: Server type - `"stdio"` (default) or `"sse"` (optional)
  - `port`: Port number (required for SSE servers, ignored for stdio)
- `server.add_tool(name, &block)` - Register a tool with a block that receives parameters
- `server.start` - Start the server and listen for requests
- `server.stop` - Stop the server
- `server.list_tools` - Get list of registered tools
- `server.call_tool(name, arguments)` - Call a tool directly

The server implements the MCP protocol over JSON-RPC 2.0, supporting:
- `tools/list` - List available tools
- `tools/call` - Execute a specific tool

#### Examples

**Test SSE Server with curl:**
```bash
# Health check
curl http://localhost:8080/health

# List tools
curl http://localhost:8080/tools

# Server-Sent Events
curl http://localhost:8080/sse

# Call a tool via JSON-RPC
curl -X POST http://localhost:8080/mcp \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"add","arguments":{"a":5,"b":3}}}'
```

**Test Stdio Server:**
```bash
# Send JSON-RPC to stdin
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | ruby your_server.rb
```

#### Tool Response Format

Tools should return responses in MCP format:

```ruby
{
  content: [
    { type: "text", text: "your response text" }
  ]
}
```

For simple text responses, you can return any value and it will be automatically wrapped in the proper format.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zhuangbiaowei/mcp-sdk.rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).