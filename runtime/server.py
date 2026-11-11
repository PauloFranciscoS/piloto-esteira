import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def snapshot():
    return {
        "service": os.environ.get("SERVICE", "web"),
        "version": os.environ.get("APP_VERSION", "dev"),
        "commit": os.environ.get("GIT_SHA", "unknown"),
    }


def health_status():
    if os.environ.get("HEALTH_MODE", "ok") == "fail":
        return 500
    return 200


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/health":
            code = health_status()
            body = {"status": "ok" if code == 200 else "fail"}
            self._send(code, json.dumps(body), "application/json")
            return
        if path == "/version":
            self._send(200, json.dumps(snapshot()), "application/json")
            return
        if path == "/":
            info = snapshot()
            page = (
                "<!doctype html><html lang=\"pt-BR\"><head><meta charset=\"utf-8\">"
                "<title>piloto-esteira</title></head><body>"
                f"<h1>piloto-esteira</h1><p>serviço {info['service']}</p>"
                f"<p>versão {info['version']}</p><p>commit {info['commit']}</p>"
                "</body></html>"
            )
            self._send(200, page, "text/html; charset=utf-8")
            return
        self._send(404, "não encontrado", "text/plain; charset=utf-8")

    def _send(self, code, body, content_type):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        return


def main():
    port = int(os.environ.get("PORT", "8080"))
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
