import { io } from "socket.io-client";

const SERVER = process.env.SERVER || "http://localhost:3000";
const AGENT_ID = process.env.AGENT_ID || "agent-001";

const socket = io(SERVER);

socket.on("connect", () => {
  console.log("[client] connected:", socket.id);

  socket.emit("agent:connect", { agentId: AGENT_ID }, (res: any) => {
    if (res?.ok) {
      console.log("[client] bound to agent:", res.agentId);
      // send a test message
      socket.emit("message:send", { payload: { text: "你好，我想退款" } });
      console.log("[client] sent: 你好，我想退款");
    } else {
      console.log("[client] connect failed");
    }
  });
});

socket.on("message:receive", ({ from, payload }: any) => {
  console.log(`[client] message from ${from}:`, payload);
});

socket.on("agent:taken", ({ agentId, by }: any) => {
  console.log(`[client] preempted! agent ${agentId} taken by ${by}`);
});

socket.on("agent:disconnected", ({ agentId }: any) => {
  console.log(`[client] agent ${agentId} went offline`);
});

socket.on("error", (err: any) => {
  console.log("[client] error:", err);
});

socket.on("disconnect", () => {
  console.log("[client] disconnected");
});
