#!/bin/sh
# Publishes and names every package not yet named on BendHub, in dependency
# order, and stops at the first refusal. BendHub registers at most five new
# names per account a day, so a run may stop on "too many": run it again the
# next day. A package already on the hub by hash publishes to the same hash.
#   ./publish.sh            uses `bend` from PATH
#   BEND="bun ../bend2-core/bend2/main.ts" ./publish.sh
set -eu
cd "$(dirname "$0")"
BEND=${BEND:-bend}
VERSION=0.1.0.0
HUB=${BEND_HUB:-https://hub.bend-lang.com}
for pkg in text-scan:scan byte-words:words crc32:crc32 raylib:raylib bendquest:kernel \
  xml-doc:xml bytes:bytes image:image coverage:cover deflate:deflate ustar:ustar \
  css-style:css png-decode:png jpeg-decode:jpeg truetype:font gzip-frame:gzip \
  svg-render:svg; do
  dir=${pkg%%:*}
  name=gralha-$dir@$VERSION
  if curl -fs "$HUB/name/$name" > /dev/null; then
    echo "named     $name"
    continue
  fi
  echo "publishing $name"
  (cd "$dir" && $BEND "${pkg##*:}.bend" --publish "$name")
done
