# Channel Server 接入指南

协议: Socket.IO v4 over HTTPS

Channel Server 职责: Agent 发现 + 消息转发，不存储任何聊天内容。

连接地址通过环境变量 `CHANNEL_SERVER` 获取。

---

## Agent

### 注册

```typescript
import { io } from "socket.io-client";

const socket = io(process.env.CHANNEL_SERVER, { rejectUnauthorized: false });

socket.emit("agent:register", {
  id: "agent-001",
  name: "客服助手",
  type: "customer_service",
  avatar: "headphones.circle.fill",
  avatar_color: "blue",
});
```

注册字段说明:

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | Agent 唯一标识 |
| name | string | 显示名称 |
| type | string | Agent 类型 |
| avatar | string | 头像（SF Symbol 名称） |
| avatar_color | string | 头像颜色 |

### 监听事件

```typescript
// Client 接入
socket.on("client:connected", ({ clientId }) => {});

// Client 断开（主动断开或被抢占）
socket.on("client:disconnected", () => {});

// 收到消息
socket.on("message:receive", ({ from, payload }) => {});
```

### 发送消息

```typescript
socket.emit("message:send", { payload: { text: "你好" } });
```

不需要指定目标，Channel Server 根据 1:1 绑定关系自动路由到当前 Client。

---

## Client

### 连接 Agent

无需注册，直接连接:

```typescript
import { io } from "socket.io-client";

const socket = io(process.env.CHANNEL_SERVER, { rejectUnauthorized: false });

socket.emit("agent:connect", { agentId: "agent-001" }, (res) => {
  // res: { ok: true, agentId: "agent-001" }
});
```

同一个 Agent 同时只服务一个 Client。后连接的 Client 会抢占前一个。

### 监听事件

```typescript
// 被其他 Client 抢占
socket.on("agent:taken", ({ agentId, by }) => {});

// Agent 下线
socket.on("agent:disconnected", ({ agentId }) => {});

// 收到消息
socket.on("message:receive", ({ from, payload }) => {});
```

### 发送消息

```typescript
socket.emit("message:send", { payload: { text: "我要退款" } });
```

同样不需要指定目标，自动路由到绑定的 Agent。

---

## payload

`payload` 是任意 JSON，Channel Server 只做透传。Agent 和 Client 自行约定结构。
