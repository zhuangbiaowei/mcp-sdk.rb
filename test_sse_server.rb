#!/usr/bin/env ruby

require "./lib/mcp"

# Create SSE server as specified
server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "sse",
  port: 8080
)

# Add the addition tool as specified
server.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

# Add more example tools
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

puts "Starting MCP SSE server..."
puts "MCP SSE Protocol Flow:"
puts "1. First call:  curl http://localhost:8080/sse"
puts "   Returns:     event: endpoint\\ndata: /mcp/message"
puts ""
puts "2. Then call:   curl -X POST http://localhost:8080/mcp/message -H 'Content-Type: application/json' -d 'JSON-RPC'"
puts "   Returns:     data: {JSON-RPC response}"
puts ""
puts "Test commands:"
puts "  curl http://localhost:8080/health"
puts "  curl http://localhost:8080/sse"
puts "  curl -X POST http://localhost:8080/mcp/message -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}'"
puts "  curl -X POST http://localhost:8080/mcp/message -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"add\",\"arguments\":{\"a\":5,\"b\":3}}}'"

begin
  server.start
rescue Interrupt
  puts "\nServer shutting down..."
  server.stop
end