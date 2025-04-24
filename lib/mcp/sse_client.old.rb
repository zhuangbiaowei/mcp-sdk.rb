require "http"
require "uri"

module MCP
  class SSEClient
    DEFAULT_RECONNECT_TIME = 3000 # 3 seconds in ms
    attr_accessor :connection_thread

    def initialize(url, headers: {})
      @url = URI(url)
      @headers = headers
      @last_event_id = ""
      @reconnect_time = DEFAULT_RECONNECT_TIME
      @event_listeners = {}
      @should_reconnect = true
    end

    def on(event_name = "message", &block)
      @event_listeners[event_name] ||= []
      @event_listeners[event_name] << block
    end

    def start
      connect
    end

    def status
      @connection_thread
    end

    def close
      @should_reconnect = false
      @connection_thread&.kill
      @connection&.close
    end

    private

    def connect
      @connection_thread = Thread.new do
        begin
          @connection = HTTP.headers(headers)
            .timeout(connect: 5, read: 60)
            .get(@url, stream: true)

          buffer = ""
          event_type = "message"

          @connection.body.each do |chunk|
            buffer += chunk.to_s
            while line = buffer.slice!(/^.*\n/)
              line.chomp!
              process_line(line, event_type)
            end
          end
        rescue => e
          dispatch_event("error", error: e)
          schedule_reconnect if @should_reconnect
        end
      end
    end

    def headers
      {
        "Accept" => "text/event-stream",
        "Cache-Control" => "no-cache",
        "Last-Event-ID" => @last_event_id,
      }.merge(@headers).reject { |k, v| v.nil? || v.empty? }
    end

    def process_line(line, event_type)
      if line.empty?
        dispatch_event(event_type)
        event_type = "message" # Reset to default
      elsif line.start_with?(":")
        # Comment line, ignore
      elsif line.include?(":")
        field, value = line.split(":", 2)
        value = value.strip unless value.nil?

        case field
        when "event"
          event_type = value
        when "data"
          @data_buffer ||= ""
          @data_buffer += value + "\n"
        when "id"
          @last_event_id = value unless value.include?("\u0000")
        when "retry"
          @reconnect_time = value.to_i if value =~ /^\d+$/
        end
      end
    end

    def dispatch_event(event_type, data: @data_buffer, error: nil)
      if @data_buffer
        @data_buffer = @data_buffer.chomp if @data_buffer.end_with?("\n")
        @data_buffer = nil
      end

      listeners = @event_listeners[event_type] || []
      listeners.each { |l| l.call(data, error) }
    end

    def schedule_reconnect
      sleep(@reconnect_time / 1000.0)
      connect if @should_reconnect
    end
  end
end
