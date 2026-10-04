#!/bin/sh
# usage: sh fidget.sh start|stop|loop   (Windows -> fidget.ps1, macOS -> afplay, Linux -> paplay/aplay)
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) exec powershell -NoProfile -ExecutionPolicy Bypass -File "${0%fidget.sh}fidget.ps1" "$1" ;;
esac
d=$(cd "$(dirname "$0")" && pwd)
pidf="${TMPDIR:-/tmp}/claude-fidget.pid"
halt() { [ -f "$pidf" ] && kill "$(cat "$pidf")" 2>/dev/null; rm -f "$pidf"; }

case "$1" in
  stop) halt ;;
  start)
    halt
    nohup sh "$0" loop >/dev/null 2>&1 &
    echo $! > "$pidf"
    ;;
  loop)
    # ponytail: Esc-interrupt fires no Stop hook, so the loop dies on its own after 15 min (or on next prompt)
    end=$(( $(date +%s) + 900 ))
    while [ "$(date +%s)" -lt "$end" ]; do
      sleep "${FIDGET_INTERVAL:-30}"
      set -- "$d"/sounds/*.wav
      shift $(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % $# ))
      afplay "$1" 2>/dev/null || paplay "$1" 2>/dev/null || aplay -q "$1" 2>/dev/null
    done
    rm -f "$pidf"
    ;;
esac
