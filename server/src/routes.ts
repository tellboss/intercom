import { getOnlineAgents } from "./socket";

export function handleRequest(req: Request): Response | null {
  const url = new URL(req.url);
  if (req.method !== "GET") return null;

  if (url.pathname === "/api/agents") {
    return Response.json(getOnlineAgents());
  }
  if (url.pathname === "/health") {
    return Response.json({ ok: true });
  }
  return null;
}
