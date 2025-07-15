#!/usr/bin/env ruby

require_relative 'lib/mcp'
require 'net/http'
require 'json'

def test_enhanced_sse_server
  puts "Testing Enhanced SSE Server Integration"
  puts "======================================"
  
  # Create server
  server = MCP::Server.new(
    name: "Test Enhanced Server",
    version: "1.0.0",
    type: "enhanced_sse",
    port: 8082
  )
  
  # Add test tool
  server.add_tool("test") do |params|
    {
      content: [{ type: "text", text: "Test successful: #{params.inspect}" }]
    }
  end
  
  # Start server in a separate thread
  server_thread = Thread.new do
    begin
      server.start
    rescue => e
      puts "Server error: #{e.message}"
    end
  end
  
  # Give server time to start
  sleep 3
  
  puts "Server started, running tests..."
  
  # Test 1: Health check
  begin
    uri = URI('http://localhost:8082/health')
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      health_data = JSON.parse(response.body)
      puts "✓ Health check passed"
      puts "  Server: #{health_data['server']}"
      puts "  Type: #{health_data['type']}"
      puts "  Tools: #{health_data['tools_count']}"
    else
      puts "✗ Health check failed: #{response.code}"
    end
  rescue => e
    puts "✗ Health check error: #{e.message}"
  end
  
  # Test 2: SSE endpoint
  begin
    uri = URI('http://localhost:8082/sse')
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200' && response['content-type'].include?('text/event-stream')
      puts "✓ SSE endpoint working"
      puts "  Content-Type: #{response['content-type']}"
      puts "  Response: #{response.body.strip}"
    else
      puts "✗ SSE endpoint failed: #{response.code}"
    end
  rescue => e
    puts "✗ SSE endpoint error: #{e.message}"
  end
  
  # Test 3: MCP message endpoint
  begin
    uri = URI('http://localhost:8082/mcp/message')
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/list"
    })
    
    response = http.request(request)
    
    if response.code == '200'
      puts "✓ MCP message endpoint working"
      puts "  Response: #{response.body.strip}"
      
      # Parse SSE response
      if response.body.include?('data: ')
        data_line = response.body.lines.find { |line| line.start_with?('data: ') }
        if data_line
          json_data = data_line.sub('data: ', '').strip
          parsed = JSON.parse(json_data)
          if parsed['result'] && parsed['result']['tools']
            puts "  Tools found: #{parsed['result']['tools'].length}"
          end
        end
      end
    else
      puts "✗ MCP message endpoint failed: #{response.code}"
    end
  rescue => e
    puts "✗ MCP message endpoint error: #{e.message}"
  end
  
  # Test 4: Tool call
  begin
    uri = URI('http://localhost:8082/mcp/message')
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate({
      jsonrpc: "2.0",
      id: 2,
      method: "tools/call",
      params: {
        name: "test",
        arguments: { message: "Hello Angelo!" }
      }
    })
    
    response = http.request(request)
    
    if response.code == '200'
      puts "✓ Tool call working"
      puts "  Response: #{response.body.strip}"
    else
      puts "✗ Tool call failed: #{response.code}"
    end
  rescue => e
    puts "✗ Tool call error: #{e.message}"
  end
  
  puts "\nTest completed. Stopping server..."
  
  # Stop server
  server.stop
  server_thread.kill
  
  puts "Enhanced SSE server integration test finished."
end

# Run the test
if __FILE__ == $0
  test_enhanced_sse_server
end