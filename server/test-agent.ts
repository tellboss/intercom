import { io } from "socket.io-client";

const SERVER = process.env.SERVER || "https://47.116.5.76";

const socket = io(SERVER, { rejectUnauthorized: false });

socket.on("connect", () => {
  console.log("[agent] connected:", socket.id);

  socket.emit("agent:register", {
    id: "agent-001",
    name: "客服助手",
    type: "customer_service",
    avatar: "headphones.circle.fill",
    avatar_color: "blue",
  }, (res: any) => {
    console.log("[agent] registered:", res.name);
  });
});

socket.on("client:connected", ({ clientId }: any) => {
  console.log("[agent] client connected:", clientId);
});

socket.on("client:disconnected", () => {
  console.log("[agent] client disconnected");
});

socket.on("message:receive", ({ from, payload }: any) => {
  console.log(`[agent] message from ${from}:`, payload);

  // echo reply
  const reply = { text: `收到: "${payload.text}"` };
  socket.emit("message:send", { payload: reply });
  console.log("[agent] replied:", reply);
});

socket.on("disconnect", () => {
  console.log("[agent] disconnected");
});
