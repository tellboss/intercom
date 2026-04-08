import type { Server, Socket } from "socket.io";

interface AgentInfo {
  id: string;
  name: string;
  type: string;
  avatar: string;
  avatar_color: string;
}

// agentId -> { socketId, info }
const agents = new Map<string, { socketId: string; info: AgentInfo }>();

// 1:1 binding
const agentToClient = new Map<string, string>(); // agentId -> client socket.id
const clientToAgent = new Map<string, string>(); // client socket.id -> agentId

function getOnlineAgents(): AgentInfo[] {
  return [...agents.values()].map((a) => a.info);
}

function bindPair(agentId: string, clientSocketId: string, io: Server) {
  const prevAgent = clientToAgent.get(clientSocketId);
  if (prevAgent && prevAgent !== agentId) {
    agentToClient.delete(prevAgent);
    const prev = agents.get(prevAgent);
    if (prev) io.to(prev.socketId).emit("client:disconnected");
  }

  const prevClient = agentToClient.get(agentId);
  if (prevClient && prevClient !== clientSocketId) {
    clientToAgent.delete(prevClient);
    io.to(prevClient).emit("agent:taken", { agentId, by: clientSocketId });
  }

  agentToClient.set(agentId, clientSocketId);
  clientToAgent.set(clientSocketId, agentId);
}

function unbindAgent(agentId: string, io: Server) {
  const clientSocketId = agentToClient.get(agentId);
  if (clientSocketId) {
    clientToAgent.delete(clientSocketId);
    agentToClient.delete(agentId);
    io.to(clientSocketId).emit("agent:disconnected", { agentId });
  }
}

function unbindClient(clientSocketId: string, io: Server) {
  const agentId = clientToAgent.get(clientSocketId);
  if (agentId) {
    agentToClient.delete(agentId);
    clientToAgent.delete(clientSocketId);
    const agent = agents.get(agentId);
    if (agent) io.to(agent.socketId).emit("client:disconnected");
  }
}

export { getOnlineAgents };

export function setupSocket(io: Server) {
  io.on("connection", (socket: Socket) => {
    console.log(`[connect] ${socket.id}`);
    let role: "agent" | "client" | null = null;
    let agentId: string | null = null;

    socket.on("agent:register", (data: AgentInfo, ack?: Function) => {
      role = "agent";
      agentId = data.id;
      agents.set(data.id, { socketId: socket.id, info: data });
      console.log(`[agent:online] ${data.name} (${data.type})`);
      io.emit("agents:updated", getOnlineAgents());
      if (ack) ack(data);
    });

    socket.on("agent:connect", (data: { agentId: string }, ack?: Function) => {
      if (role === "agent") {
        socket.emit("error", { message: "Agent cannot connect to agent" });
        return;
      }
      role = "client";
      const agent = agents.get(data.agentId);
      if (!agent) {
        socket.emit("error", { message: "Agent not online" });
        return;
      }

      bindPair(data.agentId, socket.id, io);
      console.log(`[bind] client:${socket.id} <-> agent:${data.agentId}`);
      io.to(agent.socketId).emit("client:connected", { clientId: socket.id });
      if (ack) ack({ ok: true, agentId: data.agentId });
    });

    socket.on("message:send", (data: { payload: unknown }) => {
      if (role === "client") {
        const boundAgent = clientToAgent.get(socket.id);
        if (!boundAgent) return socket.emit("error", { message: "Not connected to agent" });
        const agent = agents.get(boundAgent);
        if (agent) io.to(agent.socketId).emit("message:receive", { from: socket.id, payload: data.payload });
      } else if (role === "agent" && agentId) {
        const clientSocketId = agentToClient.get(agentId);
        if (!clientSocketId) return socket.emit("error", { message: "No client connected" });
        io.to(clientSocketId).emit("message:receive", { from: agentId, payload: data.payload });
      }
    });

    socket.on("disconnect", () => {
      console.log(`[disconnect] ${socket.id} (${role})`);
      if (role === "agent" && agentId) {
        unbindAgent(agentId, io);
        agents.delete(agentId);
        io.emit("agents:updated", getOnlineAgents());
      } else if (role === "client") {
        unbindClient(socket.id, io);
      }
    });
  });
}
