#!/usr/bin/env ruby

require_relative 'lib/mcp'

# Example: Enhanced SSE Server Usage
puts "MCP Enhanced SSE Server Example"
puts "================================"

# Create MCP server with Enhanced SSE support
server = MCP::Server.new(
  name: "Enhanced SSE Demo",
  version: "1.0.0",
  type: "enhanced_sse",
  port: 8081
)

# Add some example tools
server.add_tool("add") do |params|
  a = params["a"] || 0
  b = params["b"] || 0
  result = a + b
  {
    content: [{ type: "text", text: "#{a} + #{b} = #{result}" }]
  }
end

server.add_tool("multiply") do |params|
  x = params["x"] || 1
  y = params["y"] || 1
  result = x * y
  {
    content: [{ type: "text", text: "#{x} × #{y} = #{result}" }]
  }
end

server.add_tool("greet") do |params|
  name = params["name"] || "World"
  {
    content: [{ type: "text", text: "Hello, #{name}! (from Enhanced SSE Server)" }]
  }
end

server.add_tool("current_time") do |params|
  timezone = params["timezone"] || "UTC"
  current_time = Time.now
  {
    content: [{ 
      type: "text", 
      text: "Current time (#{timezone}): #{current_time.strftime('%Y-%m-%d %H:%M:%S %Z')}" 
    }]
  }
end

# Handle graceful shutdown
trap("INT") do
  puts "\nShutting down Enhanced SSE server..."
  server.stop
  exit
end

trap("TERM") do
  puts "\nShutting down Enhanced SSE server..."
  server.stop
  exit
end

puts "\nStarting Enhanced SSE server..."
puts "Available endpoints:"
puts "- GET  http://localhost:8081/sse"
puts "- POST http://localhost:8081/mcp/message"
puts "- GET  http://localhost:8081/sse/events (Advanced SSE)"
puts "- POST http://localhost:8081/mcp/broadcast (Broadcast to all clients)"
puts "- WS   http://localhost:8081/ws (WebSocket)"
puts "- GET  http://localhost:8081/health"
puts "\nExample curl commands:"
puts "1. Get SSE endpoint:"
puts "   curl http://localhost:8081/sse"
puts ""
puts "2. Call a tool:"
puts "   curl -X POST http://localhost:8081/mcp/message \\"
puts "     -H \"Content-Type: application/json\" \\"
puts "     -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"add\",\"arguments\":{\"a\":5,\"b\":3}}}'"
puts ""
puts "3. List available tools:"
puts "   curl -X POST http://localhost:8081/mcp/message \\"
puts "     -H \"Content-Type: application/json\" \\"
puts "     -d '{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\"}'"
puts ""
puts "4. Health check:"
puts "   curl http://localhost:8081/health"
puts ""
puts "5. SSE Events (keep connection open):"
puts "   curl -N http://localhost:8081/sse/events"
puts ""
puts "Press Ctrl+C to stop the server"
puts "================================"

# Start the server
begin
  server.start
rescue => e
  puts "Error starting server: #{e.message}"
  puts e.backtrace
  exit 1
end