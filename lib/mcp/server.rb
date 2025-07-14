require "json"
require "sinatra/base"
require "puma"

module MCP
  class Server
    attr_reader :name, :version, :type, :port, :tools

    def initialize(name:, version:, type: "stdio", port: nil)
      @name = name
      @version = version
      @type = type.to_s
      @port = port
      @tools = {}
      @running = false
      
      validate_configuration
    end

    def add_tool(name, &block)
      unless block_given?
        raise ArgumentError, "Block required for tool '#{name}'"
      end
      
      @tools[name.to_s] = block
    end

    def start(io_in = $stdin, io_out = $stdout)
      @running = true
      
      case @type
      when "stdio"
        start_stdio_server(io_in, io_out)
      when "sse"
        start_sse_server
      else
        raise ArgumentError, "Unknown server type: #{@type}"
      end
    end

    def stop
      @running = false
      @sse_server.stop if @sse_server
    end

    def list_tools
      tool_list = @tools.keys.map do |tool_name|
        {
          name: tool_name,
          description: "Tool: #{tool_name}",
          inputSchema: {
            type: "object",
            properties: {},
            required: []
          }
        }
      end

      {
        tools: tool_list
      }
    end

    def call_tool(name, arguments = {})
      tool_name = name.to_s
      
      unless @tools.key?(tool_name)
        raise Error, "Tool '#{tool_name}' not found"
      end

      begin
        result = @tools[tool_name].call(arguments)
        
        # Ensure result has the expected MCP format
        if result.is_a?(Hash) && result.key?(:content)
          result
        else
          # Wrap simple results in MCP format
          {
            content: [{ type: "text", text: result.to_s }]
          }
        end
      rescue => e
        raise Error, "Error executing tool '#{tool_name}': #{e.message}"
      end
    end

    private

    def validate_configuration
      case @type
      when "stdio"
        # No additional validation needed for stdio
      when "sse"
        if @port.nil?
          raise ArgumentError, "Port is required for SSE server type"
        end
        unless @port.is_a?(Integer) && @port > 0 && @port < 65536
          raise ArgumentError, "Port must be a valid integer between 1 and 65535"
        end
      else
        raise ArgumentError, "Server type must be 'stdio' or 'sse'"
      end
    end

    def start_stdio_server(io_in, io_out)
      @io_in = io_in
      @io_out = io_out
      
      puts "MCP Server '#{@name}' v#{@version} (stdio) starting..."
      puts "Available tools: #{@tools.keys.join(', ')}"
      puts "Ready to accept JSON-RPC requests on stdin..."
      
      process_stdio_requests
    end

    def start_sse_server
      puts "MCP Server '#{@name}' v#{@version} (SSE) starting on port #{@port}..."
      puts "Available tools: #{@tools.keys.join(', ')}"
      
      app = create_sse_app
      @sse_server = Puma::Server.new(app)
      @sse_server.add_tcp_listener("0.0.0.0", @port)
      
      puts "SSE Server ready at http://localhost:#{@port}"
      puts "Endpoints:"
      puts "  GET /sse - Server-Sent Events endpoint"
      puts "  POST /mcp - JSON-RPC endpoint"
      puts "  GET /tools - List tools"
      puts "  GET /health - Health check"
      
      @sse_server.run.join
    end

    def process_stdio_requests
      while @running
        begin
          line = @io_in.gets
          break unless line
          
          line = line.strip
          next if line.empty?
          
          request = JSON.parse(line)
          response = handle_request(request)
          
          @io_out.puts response.to_json
          @io_out.flush
        rescue JSON::ParserError => e
          send_stdio_error_response(nil, -32700, "Parse error: #{e.message}")
        rescue => e
          send_stdio_error_response(nil, -32603, "Internal error: #{e.message}")
        end
      end
    end

    def create_sse_app
      server_instance = self
      
      Sinatra.new do
        set :server, :puma
        set :bind, '0.0.0.0'
        set :port, server_instance.port
        
        # Enable CORS
        before do
          headers 'Access-Control-Allow-Origin' => '*',
                  'Access-Control-Allow-Methods' => ['GET', 'POST', 'OPTIONS'],
                  'Access-Control-Allow-Headers' => 'Content-Type'
        end
        
        options '*' do
          200
        end
        
        # SSE endpoint for streaming
        get '/sse' do
          content_type 'text/event-stream'
          headers 'Cache-Control' => 'no-cache',
                  'Connection' => 'keep-alive'
          
          stream do |out|
            # Send initial connection message
            out << "data: #{JSON.generate({
              type: 'connection',
              server: {
                name: server_instance.name,
                version: server_instance.version,
                tools: server_instance.list_tools
              }
            })}\n\n"
            
            # Keep connection alive with heartbeat
            begin
              loop do
                sleep 30
                out << "data: #{JSON.generate({type: 'heartbeat', timestamp: Time.now.to_i})}\n\n"
              end
            rescue => e
              # Client disconnected
            end
          end
        end
        
        # JSON-RPC endpoint
        post '/mcp' do
          content_type 'application/json'
          
          begin
            request_data = JSON.parse(request.body.read)
            response = server_instance.send(:handle_request, request_data)
            response.to_json
          rescue JSON::ParserError => e
            status 400
            {
              jsonrpc: "2.0",
              id: nil,
              error: {
                code: -32700,
                message: "Parse error: #{e.message}"
              }
            }.to_json
          rescue => e
            status 500
            {
              jsonrpc: "2.0", 
              id: nil,
              error: {
                code: -32603,
                message: "Internal error: #{e.message}"
              }
            }.to_json
          end
        end
        
        # Tool list endpoint (convenience)
        get '/tools' do
          content_type 'application/json'
          server_instance.list_tools.to_json
        end
        
        # Health check
        get '/health' do
          content_type 'application/json'
          {
            status: 'ok',
            server: server_instance.name,
            version: server_instance.version,
            type: server_instance.type,
            tools_count: server_instance.tools.size
          }.to_json
        end
      end
    end

    def handle_request(request)
      request_id = request["id"]
      method = request["method"]
      params = request["params"] || {}

      case method
      when "tools/list"
        {
          jsonrpc: "2.0",
          id: request_id,
          result: list_tools
        }
      when "tools/call"
        tool_name = params["name"]
        arguments = params["arguments"] || {}
        
        begin
          result = call_tool(tool_name, arguments)
          {
            jsonrpc: "2.0",
            id: request_id,
            result: result
          }
        rescue Error => e
          {
            jsonrpc: "2.0",
            id: request_id,
            error: {
              code: -32000,
              message: e.message
            }
          }
        end
      else
        {
          jsonrpc: "2.0",
          id: request_id,
          error: {
            code: -32601,
            message: "Method not found: #{method}"
          }
        }
      end
    end

    def send_stdio_error_response(request_id, code, message)
      response = {
        jsonrpc: "2.0",
        id: request_id,
        error: {
          code: code,
          message: message
        }
      }
      
      @io_out.puts response.to_json
      @io_out.flush
    end
  end
end