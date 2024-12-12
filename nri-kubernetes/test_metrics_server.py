"""
This script starts an HTTP server on port 8080 to serve Prometheus-style metrics.

**Key Features:**
1. **/metrics endpoint**: Returns a test metric `test_metric{label="test"} 1.0` in Prometheus format.
2. **Request Logging**: Logs incoming requests (path + headers) to /tmp/request.log.
3. **404 Handling**: Returns a 404 response for all endpoints except /metrics.
"""
import http.server
import socketserver
import time
import json

class MetricsHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Log request details
        with open('/tmp/request.log', 'a') as log:
            log.write(f"Request received at {time.time()}: {self.path}\n")
            log.write(f"Headers: {json.dumps(dict(self.headers))}\n")

        if self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            metrics = '''
            # HELP test_metric Test metric for nri-kubernetes
            # TYPE test_metric gauge
            test_metric{label="test"} 1.0
            '''
            self.wfile.write(metrics.encode())
        else:
            self.send_response(404)
            self.end_headers()

with socketserver.TCPServer(("", 8080), MetricsHandler) as httpd:
    httpd.serve_forever()
