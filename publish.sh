#!/bin/sh
# Publishes and names every package not yet named on BendHub, in dependency
# order, and stops at the first refusal. BendHub registers at most five new
# names per account a day, so a run may stop on "too many": run it again the
# next day. A package already on the hub by hash publishes to the same hash.
# Each entry is dir:file:version; bump a version when the package or one
# of its gralha imports changes.
#   ./publish.sh            uses `bend` from PATH
#   BEND="bun ../bend2-core/bend2/main.ts" ./publish.sh
set -eu
cd "$(dirname "$0")"
BEND=${BEND:-bend}
HUB=${BEND_HUB:-https://hub.bend-lang.com}
for pkg in text-scan:scan:0.1.0.1 byte-words:words:0.1.0.0 \
  crc32:crc32:0.1.0.0 raylib:raylib:0.1.0.0 bendquest:kernel:0.1.0.0 \
  xml-doc:xml:0.1.0.1 bytes:bytes:0.1.0.1 image:image:0.1.0.1 \
  coverage:cover:0.1.0.1 deflate:deflate:0.1.0.0 ustar:ustar:0.1.0.0 \
  css-style:css:0.1.0.1 png-decode:png:0.1.0.1 jpeg-decode:jpeg:0.1.0.1 \
  truetype:font:0.1.0.1 gzip-frame:gzip:0.1.0.0 svg-render:svg:0.1.0.1 \
  http-core:http:0.1.0.0 http-server:server:0.1.0.0; do
  dir=${pkg%%:*}
  file=${pkg#*:}
  file=${file%%:*}
  name=gralha-$dir@${pkg##*:}
  if curl -fs "$HUB/name/$name" > /dev/null; then
    echo "named     $name"
    continue
  fi
  echo "publishing $name"
  (cd "$dir" && $BEND "$file.bend" --publish "$name")
done
