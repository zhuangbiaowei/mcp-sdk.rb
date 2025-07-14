#!/usr/bin/env ruby

require "./lib/mcp"
require "json"

# Test the server functionality directly without stdio
server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0"
)

# Add the addition tool as specified
server.add_tool("add") do |params|
  result = params["a"] + params["b"]
  {
    content: [{ type: "text", text: result.to_s }]
  }
end

puts "Testing MCP Server functionality..."
puts "=================================="

# Test 1: List tools
puts "\n1. Testing tools/list:"
tools_result = server.list_tools
puts JSON.pretty_generate(tools_result)

# Test 2: Call the add tool
puts "\n2. Testing tools/call with add tool:"
begin
  add_result = server.call_tool("add", {"a" => 5, "b" => 3})
  puts JSON.pretty_generate(add_result)
rescue => e
  puts "Error: #{e.message}"
end

# Test 3: Test error handling for non-existent tool
puts "\n3. Testing error handling:"
begin
  server.call_tool("nonexistent", {})
rescue MCP::Error => e
  puts "Expected error: #{e.message}"
end

puts "\n✅ Server implementation test completed!"