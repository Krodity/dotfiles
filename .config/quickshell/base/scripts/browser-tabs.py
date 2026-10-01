#!/usr/bin/env python3
"""Per-tab browser media for the media card, via the Beam broker.

A browser shows ALL its tabs through one MPRIS player, so the shell can't see or pick
tabs itself. The Beam extension (loaded in Chrome + Chromium) can; the broker on
127.0.0.1:8780 routes calls to it.

    browser-tabs.py list                    → {"hosts": [{id, name, brand, tabs: [...]}]}
    browser-tabs.py play|pause|show <host> <tabId>

`play` pauses that browser's other tabs first, so its MPRIS player moves to this one.
Prints {"hosts": []} / {"error": …} instead of failing when the broker is down.
"""
import json, pathlib, socket, sys, urllib.request
from concurrent.futures import ThreadPoolExecutor

BROKER = "http://127.0.0.1:8780"
TOKEN_FILE = pathlib.Path.home() / ".config/beam/token"


def call(path, body=None, timeout=8):
    req = urllib.request.Request(
        BROKER + path, json.dumps(body).encode() if body is not None else None,
        {"Authorization": f"Bearer {TOKEN_FILE.read_text().strip()}",
         "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def rpc(host, method, **params):
    return call("/api/rpc", {"host": host, "method": method, "params": params}, timeout=30)


def brand(name):
    # Hosts are named "<hostname> <browser brand>", e.g. "your-user Google Chrome".
    prefix = socket.gethostname() + " "
    return name[len(prefix):] if name.startswith(prefix) else name


def list_tabs():
    hosts = call("/api/hosts")["hosts"]

    def one(h):
        try:
            tabs = rpc(h["id"], "mediaTabs")["result"]["tabs"]
        except Exception:
            tabs = []
        return {"id": h["id"], "name": h["name"], "brand": brand(h["name"]), "tabs": tabs}

    with ThreadPoolExecutor(max_workers=4) as ex:
        return {"hosts": list(ex.map(one, hosts))}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    try:
        if cmd == "list":
            out = list_tabs()
        elif cmd in ("play", "pause", "show"):
            method = {"play": "mediaPlay", "pause": "mediaPause", "show": "showTab"}[cmd]
            out = rpc(sys.argv[2], method, tabId=int(sys.argv[3]))
        else:
            out = {"error": f"unknown command {cmd}"}
    except Exception as e:
        out = {"hosts": [], "error": str(e)} if cmd == "list" else {"error": str(e)}
    print(json.dumps(out))


if __name__ == "__main__":
    main()
