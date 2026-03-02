from __future__ import annotations

from langchain_core.messages import AIMessage, HumanMessage
from langchain_groq import ChatGroq
from langchain_ollama import ChatOllama
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import END, START, MessagesState, StateGraph
from langgraph.prebuilt import ToolNode, tools_condition

from app.config import settings
from app.mcp_client import MCPToolClient


class ChatAgent:
    def __init__(self) -> None:
        self.llm = self._build_llm()
        self.tools = self._load_mcp_tools()
        self.tool_node = ToolNode(self.tools) if self.tools else None
        self.model = self.llm.bind_tools(self.tools) if self.tools else self.llm
        self.graph = self._build_graph()

    def _build_llm(self):
        provider = settings.llm_provider.lower().strip()

        if provider == "ollama":
            return ChatOllama(model=settings.llm_model, temperature=0)
        if provider == "groq":
            return ChatGroq(
                model=settings.groq_llm_model,
                api_key=settings.groq_api_key,
                temperature=0,
            )

        raise ValueError(
            f"Unsupported LLM_PROVIDER='{settings.llm_provider}'. "
            "Start with 'ollama' and add more providers as needed."
        )

    def _load_mcp_tools(self):
        if not settings.mcp_enabled:
            return []

        servers = settings.mcp_servers()
        client = MCPToolClient(servers)
        return client.load_tools()

    def _call_model(self, state: MessagesState) -> MessagesState:
        response = self.model.invoke(state["messages"])
        if not isinstance(response, AIMessage):
            response = AIMessage(content=str(response))
        return {"messages": [response]}

    def _build_graph(self):
        graph = StateGraph(MessagesState)
        graph.add_node("assistant", self._call_model)

        if self.tool_node is not None:
            graph.add_node("tools", self.tool_node)
            graph.add_edge(START, "assistant")
            graph.add_conditional_edges("assistant", tools_condition)
            graph.add_edge("tools", "assistant")
        else:
            graph.add_edge(START, "assistant")
            graph.add_edge("assistant", END)

        # MemorySaver keeps short-term state by thread_id.
        # Later, you can swap this for a durable checkpointer.
        return graph.compile(checkpointer=MemorySaver())

    def chat(self, prompt: str, thread_id: str = "default") -> str:
        result = self.graph.invoke(
            {"messages": [HumanMessage(content=prompt)]},
            config={"configurable": {"thread_id": thread_id}},
        )
        messages = result.get("messages", [])
        if not messages:
            return ""
        return str(messages[-1].content)


agent = ChatAgent()
