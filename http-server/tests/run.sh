#!/bin/sh
# Runs tests/serve.bend on the JS lane and as a native binary, drives it
# with curl and nc, and compares what both answer with tests/serve.expected.
#   BEND="bun ../../bend2-core/bend2/main.ts" ./tests/run.sh   (from http-server/)
set -eu
cd "$(dirname "$0")"
BEND=${BEND:-bend}
OUT=${TMPDIR:-/tmp}/gralha-http-server-test
mkdir -p "$OUT"
drive() {
  # a refused connection does not use up one of the server's requests
  for i in $(seq 300); do curl -s -i http://127.0.0.1:18089/ && break; sleep 0.1; done
  echo; curl -s -i -X POST --data-binary 'héllo body' http://127.0.0.1:18089/echo
  echo; curl -s -i 'http://127.0.0.1:18089/q?name=caf%C3%A9+au%20lait&x=1'
  echo; curl -s -i http://127.0.0.1:18089/missing
  echo; printf 'garbage\r\n\r\n' | nc 127.0.0.1 18089
  echo; curl -s -i http://127.0.0.1:18089/raw
  echo
}
run() {
  "$@" > "$OUT/server.out" 2>&1 &
  pid=$!
  drive | tr -d '\r' | grep -v '^Date:' > "$OUT/client.out"
  wait $pid
  cat "$OUT/client.out" "$OUT/server.out"
}
run $BEND serve.bend > "$OUT/js.out"
$BEND serve.bend -o "$OUT/serve" > /dev/null
run "$OUT/serve" > "$OUT/c.out"
diff serve.expected "$OUT/js.out" && diff serve.expected "$OUT/c.out" && echo "PASS: JS and C"
