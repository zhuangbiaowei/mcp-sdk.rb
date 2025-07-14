#!/usr/bin/env ruby

require "./lib/mcp"

# Create stdio server as specified
server = MCP::Server.new(
  name: "Demo",
  version: "1.0.0",
  type: "stdio"
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

puts "Example JSON-RPC requests to test:"
puts '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
puts '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"add","arguments":{"a":5,"b":3}}}'
puts '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"greet","arguments":{"name":"Ruby"}}}'
puts "-" * 50

begin
  server.start
rescue Interrupt
  puts "\nServer shutting down..."
  server.stop
end