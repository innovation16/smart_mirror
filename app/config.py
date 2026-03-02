import json
from typing import Any

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    llm_provider: str = "ollama"
    llm_model: str = "llama3.1:8b"
    groq_api_key: str = ""
    groq_llm_model: str = "llama-3.3-70b-versatile"
    port: int = 8000

    mcp_enabled: bool = False
    # JSON array of MCP server definitions.
    # Example:
    # [
    #   {
    #     "name": "filesystem",
    #     "transport": "stdio",
    #     "command": "npx",
    #     "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    #   }
    # ]
    mcp_servers_json: str = "[]"

    def mcp_servers(self) -> list[dict[str, Any]]:
        try:
            raw = json.loads(self.mcp_servers_json)
        except json.JSONDecodeError as exc:
            raise ValueError("MCP_SERVERS_JSON must be valid JSON") from exc

        if not isinstance(raw, list):
            raise ValueError("MCP_SERVERS_JSON must be a JSON array")

        servers: list[dict[str, Any]] = []
        for idx, item in enumerate(raw):
            if not isinstance(item, dict):
                raise ValueError(f"MCP server entry at index {idx} must be an object")
            if "name" not in item:
                raise ValueError(f"MCP server entry at index {idx} is missing 'name'")
            servers.append(item)
        return servers


settings = Settings()
