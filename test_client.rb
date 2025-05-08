require "./lib/mcp"
client = MCP::SSEClient.new("https://mcp.amap.com/sse?key=key")
client.start
mcp_server_json = client.list_tools
puts JSON.pretty_generate(convertFormat(mcp_server_json))
