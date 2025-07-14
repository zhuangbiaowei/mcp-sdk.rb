#!/usr/bin/env ruby

require "./lib/mcp"

# Create server with name and version as requested
server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0"
)

# Add an addition tool exactly as requested
server.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

# Add a few more tools for demonstration
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

# Start the server (this will block and process JSON-RPC requests from stdin)
puts "MCP Server '#{server.name}' v#{server.version} starting..."
puts "Available tools: #{server.tools.keys.join(', ')}"
puts "Ready to accept JSON-RPC requests..."

server.start