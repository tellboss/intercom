import { createServer as createHttpsServer } from "node:https";
import { execSync } from "node:child_process";
import { existsSync, readFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { Server } from "socket.io";
import { setupSocket } from "./socket";
import { handleRequest } from "./routes";

const PORT = Number(process.env.PORT) || 3000;
const CERT_DIR = join(import.meta.dir, "..", "certs");
const KEY_PATH = join(CERT_DIR, "key.pem");
const CERT_PATH = join(CERT_DIR, "cert.pem");

function ensureCerts() {
  if (existsSync(KEY_PATH) && existsSync(CERT_PATH)) return;
  mkdirSync(CERT_DIR, { recursive: true });
  console.log("Generating self-signed certificate...");
  execSync(
    `openssl req -x509 -newkey rsa:2048 -keyout "${KEY_PATH}" -out "${CERT_PATH}" -days 365 -nodes -subj "/CN=localhost"`,
    { stdio: "pipe" }
  );
  console.log("Certificate generated at", CERT_DIR);
}

ensureCerts();

const handler = (req: any, res: any) => {
  const url = `https://0.0.0.0:${PORT}${req.url}`;
  const response = handleRequest(new Request(url, { method: req.method }));

  if (response) {
    response.json().then((body: any) => {
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
};

const httpsServer = createHttpsServer(
  { key: readFileSync(KEY_PATH), cert: readFileSync(CERT_PATH) },
  handler
);

const io = new Server(httpsServer, {
  cors: { origin: "*", methods: ["GET", "POST"] },
});

setupSocket(io);

httpsServer.listen(PORT, () => {
  console.log(`Server running on https://0.0.0.0:${PORT}`);
});
