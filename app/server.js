const http = require("http");

const port = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  if (req.url === "/healthz") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok" }));
    return;
  }

  if (req.url === "/") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        service: "wallet-api",
        message: "hello from dexter wallet",
      })
    );
    return;
  }

  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "not found" }));
});

// Only start listening when run directly, so tests can import the
// server and manage its lifecycle themselves.
if (require.main === module) {
  server.listen(port, () => {
    console.log(`wallet-api listening on :${port}`);
  });

  // ECS sends SIGTERM before killing the task; finish in-flight
  // requests instead of dropping them.
  process.on("SIGTERM", () => {
    console.log("SIGTERM received, shutting down");
    server.close(() => process.exit(0));
  });
}

module.exports = server;
