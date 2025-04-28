require "faraday"
require "uri"
require "json"

module MCP
  class SSEClient < StdioClient
    def initialize(url, opt = {})
      @request_id = 0
      @pending_requests = {}
      @response_queue = Queue.new
      @running = false
      @endpoint = nil
      uri = URI(url)
      @conn = Faraday.new(url: uri.origin) do |f|
        f.adapter :net_http
      end
      Thread.new do
        @conn.get do |req|
          req.url uri.request_uri
          req.headers["Accept"] = "text/event-streaml; charset=utf-8"
          req.headers["Accept-Encoding"] = "identity"
          req.headers["Content-Type"] = "application/json"

          req.options.on_data = proc do |chunk, overall_received_bytes|
            event_type = chunk.split("\n")[0].split(":")[1]
            if event_type == "endpoint"
              @endpoint = chunk.split("\n")[1][5..-1]
            end
            if event_type == "message"
              handle_response(chunk.split("\n")[1][5..-1])
            end
          end
        end
      end
    end

    def write_request(message)
      while (@endpoint == nil)
        sleep(0.2)
      end
      if @endpoint
        @conn.post(@endpoint, message, { "content-type" => "application/json" })
      end
    end

    def start
      request_id = next_id
      write_request({
        jsonrpc: "2.0",
        id: request_id,
        method: "initialize",
        params: {
          protocolVersion: "2025-04-28",
          clientInfo: { name: "mcp-ruby-client", version: "0.0.1" },
        },
      }.to_json)
      read_response(request_id)
      write_request({ jsonrpc: "2.0", method: "notifications/initialized" }.to_json)
    end
  end
end
