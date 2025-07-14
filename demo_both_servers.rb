#!/usr/bin/env ruby

require "./lib/mcp"

puts "🚀 MCP Server Demo - Both Types"
puts "================================"

# Demo 1: Stdio Server
puts "\n📤 1. STDIO SERVER DEMO"
puts "======================="

stdio_server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "stdio"
)

stdio_server.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

puts "✅ Stdio server configured:"
puts "   Name: #{stdio_server.name}"
puts "   Version: #{stdio_server.version}"
puts "   Type: #{stdio_server.type}"
puts "   Tools: #{stdio_server.tools.keys.join(', ')}"

# Test direct API call
result = stdio_server.call_tool("add", {"a" => 15, "b" => 25})
puts "   Direct test: 15 + 25 = #{result[:content][0][:text]}"

puts "\n📡 2. SSE SERVER DEMO"
puts "===================="

sse_server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "sse",
  port: 8080
)

# Add the same tool plus additional ones
sse_server.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

sse_server.add_tool("subtract") do |params|
  result = params["a"] - params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

sse_server.add_tool("status") do |params|
  {
    content: [{ 
      type: "text", 
      text: "SSE Server is running! Time: #{Time.now}" 
    }]
  }
end

puts "✅ SSE server configured:"
puts "   Name: #{sse_server.name}"
puts "   Version: #{sse_server.version}"
puts "   Type: #{sse_server.type}"
puts "   Port: #{sse_server.port}"
puts "   Tools: #{sse_server.tools.keys.join(', ')}"

# Test direct API calls
result1 = sse_server.call_tool("add", {"a" => 20, "b" => 30})
puts "   Direct test 1: 20 + 30 = #{result1[:content][0][:text]}"

result2 = sse_server.call_tool("subtract", {"a" => 50, "b" => 15})
puts "   Direct test 2: 50 - 15 = #{result2[:content][0][:text]}"

result3 = sse_server.call_tool("status", {})
puts "   Status: #{result3[:content][0][:text]}"

puts "\n🎯 USAGE INSTRUCTIONS"
puts "====================\n"

puts "💡 To start STDIO server:"
puts "   ruby -e \"require './lib/mcp'; server = MCP::Server.new(name: 'Demo', version: '1.0.0', type: 'stdio'); server.add_tool('add') { |p| {content: [{type: 'text', text: (p['a'] + p['b']).to_s}]} }; server.start\""
puts ""
puts "   Then send JSON-RPC commands:"
puts "   echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}' | ruby your_stdio_server.rb"
puts ""

puts "🌐 To start SSE server:"
puts "   ruby test_sse_server.rb"
puts ""
puts "   MCP SSE Protocol Flow:"
puts "   1. curl http://localhost:8080/sse"
puts "      Returns: event: endpoint\\ndata: /mcp/message"
puts ""
puts "   2. curl -X POST http://localhost:8080/mcp/message -H 'Content-Type: application/json' -d 'JSON-RPC'"
puts "      Returns: data: {JSON-RPC response}"
puts ""
puts "   Test commands:"
puts "   curl http://localhost:8080/health"
puts "   curl http://localhost:8080/sse"
puts "   curl -X POST http://localhost:8080/mcp/message -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}'"

puts "\n✨ Both server types are ready to use!"
puts "   Choose stdio for process-based communication"
puts "   Choose SSE for web-based applications with real-time features"