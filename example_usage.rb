#!/usr/bin/env ruby

require "./lib/mcp"

puts "MCP Server Examples"
puts "==================="

# Example 1: Create stdio server (default type)
puts "\n1. Stdio Server Example:"
server1 = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "stdio"  # or omit for default
)

# Add an addition tool as specified
server1.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

puts "✅ Stdio server created: #{server1.name} v#{server1.version}"
puts "   Type: #{server1.type}"
puts "   Tools: #{server1.tools.keys}"

# Test the tool
result = server1.call_tool("add", {"a" => 10, "b" => 5})
puts "   Test: 10 + 5 = #{result[:content][0][:text]}"

# Example 2: Create SSE server
puts "\n2. SSE Server Example:"
server2 = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "sse",
  port: 8080
)

# Add the same tools
server2.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

server2.add_tool("multiply") do |params|
  result = params["x"] * params["y"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

puts "✅ SSE server created: #{server2.name} v#{server2.version}"
puts "   Type: #{server2.type}, Port: #{server2.port}"
puts "   Tools: #{server2.tools.keys}"

# Test the tool
result = server2.call_tool("multiply", {"x" => 6, "y" => 7})
puts "   Test: 6 * 7 = #{result[:content][0][:text]}"

puts "\nUsage:"
puts "• For stdio server: server.start (listens on stdin/stdout)"
puts "• For SSE server: server.start (starts HTTP server on specified port)"
puts "\nSSE server endpoints:"
puts "  GET /sse - Server-Sent Events endpoint"
puts "  POST /mcp - JSON-RPC endpoint"
puts "  GET /tools - List tools"
puts "  GET /health - Health check"