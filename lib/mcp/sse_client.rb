module MCP
  class SSEClient < StdioClient
    def initialize(url, opt = {})
      @server = ChildProcess.build("node", File.expand_path("proxy.js",File.expand_path(File.dirname(__FILE__), "../..")), url)
      @stdout, @stdout_writer = IO.pipe
      @stderr, @stderr_writer = IO.pipe
      @server.io.stdout = @stdout_writer
      @server.io.stderr = @stderr_writer
      @server.duplex = true
      @request_id = 0
      @pending_requests = {}
      @response_queue = Queue.new
      @running = false
    end

    def start
      @server.start
      sleep 0.5 # Wait for server startup
      @running = true
      setup_io_handlers
      request_id = next_id
      write_request({
        jsonrpc: "2.0",
        id: request_id,
        method: "initialize",
        params: {
          protocolVersion: "2024-11-05",
          clientInfo: { name: "mcp-proxy", version: "0.0.1" },
        },
      }.to_json)
      read_response(request_id)
      write_request({ jsonrpc: "2.0", method: "notifications/initialized" }.to_json)
    end
  end
end
