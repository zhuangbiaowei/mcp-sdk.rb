#!/usr/bin/env ruby

require "./lib/mcp"
require "json"

puts "Testing MCP Server with Different Types"
puts "======================================="

# Test 1: Default stdio server
puts "\n1. Testing default stdio server creation:"
begin
  server1 = MCP::Server.new(
    name: "Demo",
    version: "1.0.0"
  )
  puts "✅ Default server created: type=#{server1.type}, name=#{server1.name}"
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 2: Explicit stdio server
puts "\n2. Testing explicit stdio server creation:"
begin
  server2 = MCP::Server.new(
    name: "Demo",
    version: "1.0.0",
    type: "stdio"
  )
  puts "✅ Stdio server created: type=#{server2.type}, name=#{server2.name}"
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 3: SSE server with port
puts "\n3. Testing SSE server creation:"
begin
  server3 = MCP::Server.new(
    name: "Demo",
    version: "1.0.0",
    type: "sse",
    port: 8080
  )
  puts "✅ SSE server created: type=#{server3.type}, port=#{server3.port}, name=#{server3.name}"
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 4: SSE server without port (should fail)
puts "\n4. Testing SSE server without port (should fail):"
begin
  server4 = MCP::Server.new(
    name: "Demo",
    version: "1.0.0",
    type: "sse"
  )
  puts "❌ This should have failed!"
rescue => e
  puts "✅ Expected error: #{e.message}"
end

# Test 5: Invalid server type (should fail)
puts "\n5. Testing invalid server type (should fail):"
begin
  server5 = MCP::Server.new(
    name: "Demo",
    version: "1.0.0",
    type: "invalid"
  )
  puts "❌ This should have failed!"
rescue => e
  puts "✅ Expected error: #{e.message}"
end

# Test 6: Invalid port (should fail)
puts "\n6. Testing invalid port (should fail):"
begin
  server6 = MCP::Server.new(
    name: "Demo",
    version: "1.0.0",
    type: "sse",
    port: -1
  )
  puts "❌ This should have failed!"
rescue => e
  puts "✅ Expected error: #{e.message}"
end

# Test 7: Test tools functionality
puts "\n7. Testing tools functionality:"
begin
  server = MCP::Server.new(
    name: "Demo",
    version: "1.0.0",
    type: "stdio"
  )
  
  server.add_tool("add") do |params|
    result = params["a"] + params["b"]
    {
      content: [{ type: "text", text: result.to_s }]
    }
  end
  
  result = server.call_tool("add", {"a" => 10, "b" => 5})
  puts "✅ Tool call successful: #{result[:content][0][:text]}"
  
  tools = server.list_tools
  puts "✅ Tools list: #{tools[:tools].map { |t| t[:name] }}"
rescue => e
  puts "❌ Error: #{e.message}"
end

puts "\n✅ All server type tests completed!"