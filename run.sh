#!/bin/sh
# Start the dgl-nethack container with bind-mounted state.
# Replaces any existing container of the same name (saves persist on disk).
set -eu
cd "$(dirname "$0")"

RUNTIME=${RUNTIME:-podman}
NAME=${NAME:-dgl}
PORT=${PORT:-2222}

if $RUNTIME inspect "$NAME" >/dev/null 2>&1; then
    echo "==> Removing existing container ($NAME)..."
    $RUNTIME rm -f "$NAME" >/dev/null
fi

echo "==> Starting $NAME on port $PORT..."
$RUNTIME run -d --name "$NAME" \
    --cap-add SYS_ADMIN \
    -p "$PORT:22" \
    -v "$(pwd)/runtime/dgldir:/var/dgl-chroot/dgldir:Z" \
    -v "$(pwd)/runtime/save:/var/dgl-chroot/usr/games/lib/nethackdir/save:Z" \
    -v "$(pwd)/runtime/bones:/var/dgl-chroot/usr/games/lib/nethackdir/bones:Z" \
    -v "$(pwd)/runtime/mail:/var/dgl-chroot/mail:Z" \
    -v "$(pwd)/runtime/ssh-keys:/etc/ssh/keys:Z" \
    dgl-nethack

echo "==> Connect with: ssh -p $PORT nethack@localhost"
