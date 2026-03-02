from __future__ import annotations

import asyncio
from typing import Any

from langchain_core.tools import BaseTool
from langchain_mcp_adapters.client import MultiServerMCPClient


def _server_map(servers: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    mapped: dict[str, dict[str, Any]] = {}

    for server in servers:
        name = str(server["name"])
        config = {k: v for k, v in server.items() if k != "name"}
        if "transport" not in config:
            config["transport"] = "stdio"
        mapped[name] = config

    return mapped


class MCPToolClient:
    def __init__(self, servers: list[dict[str, Any]]) -> None:
        self.servers = _server_map(servers)

    async def _load_tools_async(self) -> list[BaseTool]:
        if not self.servers:
            return []
        client = MultiServerMCPClient(self.servers)
        return await client.get_tools()

    def load_tools(self) -> list[BaseTool]:
        return asyncio.run(self._load_tools_async())
