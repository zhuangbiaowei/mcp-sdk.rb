# MCP SDK for Ruby

[![Gem Version](https://badge.fury.io/rb/mcp-sdk.rb.svg)](https://badge.fury.io/rb/mcp-sdk.rb)

A Ruby implementation of the Model Context Protocol (MCP) for connecting to MCP servers.

## Features

- Supports both SSE (Server-Sent Events) and Stdio-based MCP servers
- Type-safe client interfaces
- Easy integration with Ruby applications
- Comprehensive error handling

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mcp-sdk.rb'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install mcp-sdk.rb
```

## Usage

### Connecting to an SSE-based MCP server

```ruby
require 'mcp-sdk.rb'
client = MCP::SSEClient.new('http://example.com/sse?key=api_key')
client.start
mcp_server_json = client.list_tools
puts JSON.pretty_generate(convertFormat(mcp_server_json))
```

### Connecting to a Stdio-based MCP server

```ruby
require 'mcp-sdk.rb'

client = MCP::StdioClient.new('nodejs path/to/server_executable.js')
client.start
mcp_server_json = client.list_tools
puts JSON.pretty_generate(convertFormat(mcp_server_json))
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zhuangbiaowei/mcp-sdk.rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).