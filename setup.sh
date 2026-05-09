#!/bin/sh
# Build the dgl-nethack image and ensure the runtime/ state dirs exist.
# Re-running is safe — does not touch existing player data.
set -eu
cd "$(dirname "$0")"

RUNTIME=${RUNTIME:-$(command -v podman >/dev/null 2>&1 && echo podman || echo docker)}

echo "==> Building image (dgl-nethack) with $RUNTIME..."
$RUNTIME build -t dgl-nethack .

echo "==> Ensuring runtime/ subdirectories exist..."
mkdir -p runtime/dgldir \
         runtime/save \
         runtime/bones \
         runtime/mail \
         runtime/ssh-keys

echo "==> Done.  Run ./run.sh to start the server."
