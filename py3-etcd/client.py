import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlsplit

import etcd

# python-etcd only speaks the etcd v2 keys API, which etcd removed in 3.6.
# Serve a minimal v2 keys endpoint so the client code paths can be exercised.
store = {}


class FakeEtcdV2(BaseHTTPRequestHandler):
    def _key(self):
        return urlsplit(self.path).path[len("/v2/keys"):]

    def _reply(self, code, payload):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("X-Etcd-Index", "1")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _node(self, key):
        return {"key": key, "value": store[key], "modifiedIndex": 1, "createdIndex": 1}

    def do_PUT(self):
        key = self._key()
        length = int(self.headers.get("Content-Length", 0))
        form = parse_qs(self.rfile.read(length).decode())
        store[key] = form["value"][0]
        self._reply(201, {"action": "set", "node": self._node(key)})

    def do_GET(self):
        key = self._key()
        if key not in store:
            self._reply(404, {"errorCode": 100, "message": "Key not found", "cause": key, "index": 1})
            return
        self._reply(200, {"action": "get", "node": self._node(key)})

    def log_message(self, *args):
        pass


server = HTTPServer(("127.0.0.1", 0), FakeEtcdV2)
threading.Thread(target=server.serve_forever, daemon=True).start()

key = sys.argv[1]
value = sys.argv[2]

client = etcd.Client(host="127.0.0.1", port=server.server_address[1])
client.write(key, value)
print(client.read(key).value)

try:
    client.read("/does/not/exist")
    sys.exit("expected EtcdKeyNotFound")
except etcd.EtcdKeyNotFound:
    pass

server.shutdown()
