#!/usr/bin/env ruby

require "./lib/mcp"
require "json"

puts "Testing MCP Server JSON-RPC Integration..."
puts "=========================================="

# Create server
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

# Test JSON-RPC requests - use strings instead of symbols since JSON parsing produces strings
test_requests = [
  # List tools request
  {
    "jsonrpc" => "2.0",
    "id" => 1,
    "method" => "tools/list",
    "params" => {}
  },
  # Call add tool request
  {
    "jsonrpc" => "2.0", 
    "id" => 2,
    "method" => "tools/call",
    "params" => {
      "name" => "add",
      "arguments" => { "a" => 10, "b" => 5 }
    }
  }
]

puts "\n1. Testing JSON-RPC request handling:"

test_requests.each_with_index do |request, index|
  puts "\nRequest #{index + 1}:"
  puts JSON.pretty_generate(request)
  
  # Process request manually to test the handler
  begin
    puts "  Method: '#{request['method']}'"
    puts "  ID: #{request['id']}"
    
    response = server.send(:handle_request, request)
    puts "\nResponse #{index + 1}:"
    puts JSON.pretty_generate(response)
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(3)
  end
end

puts "\n✅ JSON-RPC integration test completed!"