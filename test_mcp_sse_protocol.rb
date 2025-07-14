#!/usr/bin/env ruby

require "./lib/mcp"

puts "🧪 Testing MCP SSE Protocol Flow"
puts "================================="

# Create SSE server following MCP SSE protocol
server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "sse",
  port: 8080
)

# Add test tools
server.add_tool("add") do |params|
  result = params["a"] + params["b"]
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

puts "✅ MCP SSE Server configured:"
puts "   Name: #{server.name}"
puts "   Version: #{server.version}"
puts "   Type: #{server.type}"
puts "   Port: #{server.port}"
puts "   Tools: #{server.tools.keys.join(', ')}"

puts "\n🔄 MCP SSE Protocol Flow:"
puts "=========================="
puts "1. Client first calls: GET http://localhost:8080/sse"
puts "   Server returns: event: endpoint\\ndata: /mcp/message"
puts ""
puts "2. Client then sends JSON-RPC to: POST http://localhost:8080/mcp/message"
puts "   Server returns SSE format with JSON-RPC response"

puts "\n📋 Test Commands:"
puts "================="
puts "# Step 1: Get the message endpoint"
puts "curl -N http://localhost:8080/sse"
puts ""
puts "# Step 2: Send JSON-RPC requests to the returned endpoint"
puts "curl -N -X POST http://localhost:8080/mcp/message \\"
puts "  -H 'Content-Type: application/json' \\"
puts "  -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}'"
puts ""
puts "curl -N -X POST http://localhost:8080/mcp/message \\"
puts "  -H 'Content-Type: application/json' \\"
puts "  -d '{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"add\",\"arguments\":{\"a\":5,\"b\":3}}}'"
puts ""
puts "curl -N -X POST http://localhost:8080/mcp/message \\"
puts "  -H 'Content-Type: application/json' \\"
puts "  -d '{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"greet\",\"arguments\":{\"name\":\"MCP\"}}}'"

puts "\n🚀 Starting MCP SSE Server..."
puts "Note: Use Ctrl+C to stop the server"
puts "=" * 50

begin
  server.start
rescue Interrupt
  puts "\n🛑 Server shutting down..."
  server.stop
end