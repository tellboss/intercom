import { createServer } from "node:http";
import { Server } from "socket.io";
import { setupSocket } from "./socket";
import { handleRequest } from "./routes";

const PORT = Number(process.env.PORT) || 3000;

const httpServer = createServer((req, res) => {
  const url = `http://0.0.0.0:${PORT}${req.url}`;
  const response = handleRequest(new Request(url, { method: req.method }));

  if (response) {
    response.json().then((body) => {
      res.writeHead(200, {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      });
      res.end(JSON.stringify(body));
    });
  } else {
    res.writeHead(404);
    res.end("Not found");
  }
});

const io = new Server(httpServer, {
  cors: { origin: "*", methods: ["GET", "POST"] },
});

setupSocket(io);

httpServer.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
