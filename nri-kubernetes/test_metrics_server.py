#!/usr/bin/env python3
"""
Mock agent that mimics newrelic-infra agent.

nri-kubernetes sends metrics to the newrelic-infra agent (not directly to cloud).
This mock listens on port 8001, accepts metrics, and logs them to /tmp/agent_received.log.
"""
import http.server
import socketserver

class AgentHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):  # noqa: ARG002
        # Suppress default logging
        pass

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)

        with open('/tmp/agent_received.log', 'a') as f:
            f.write(f"Received POST to {self.path}\n")
            f.write(f"Content-Length: {content_length}\n")
            f.write(f"Body: {body.decode('utf-8', errors='ignore')}\n")
            f.write("=" * 80 + "\n")

        # Return 204 No Content (expected by nri-kubernetes)
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        # Health check endpoint
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"status": "ready"}')

PORT = 8001
print(f"Mock agent listening on port {PORT}", flush=True)
with socketserver.TCPServer(("", PORT), AgentHandler) as httpd:
    httpd.serve_forever()
