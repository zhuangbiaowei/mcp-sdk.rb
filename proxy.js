import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { SSEClientTransport, SseError, } from "@modelcontextprotocol/sdk/client/sse.js";
import { CallToolRequestSchema, ListToolsRequestSchema, } from '@modelcontextprotocol/sdk/types.js';
import mcpProxy from "./mcpProxy.js";

const args = process.argv.slice(2);

async function getSSETransport(url){
    const headers = {};
    const transport = new SSEClientTransport(new URL(url), {
        eventSourceInit: {
            fetch: (url, init) => fetch(url, { ...init, headers }),
        },
        requestInit: {
            headers,
        },
    });
    await transport.start();
    return transport;
}

const server = new Server({
    name: 'mcp-proxy',
    version: "0.0.1",
}, {
    capabilities: {
        tools: {},
        prompts: {},
    },
});

const sseTransport = await getSSETransport(args[0]);

async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    mcpProxy({
        transportToClient: transport,
        transportToServer: sseTransport,
    });
    console.error("MCP Proxy running on stdio");
}
main().catch((error) => {
    console.error("Fatal error in main():", error);
    process.exit(1);
});
