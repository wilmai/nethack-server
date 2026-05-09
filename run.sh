#!/bin/sh
# Start the dgl-nethack container with bind-mounted state.
# Replaces any existing container of the same name (saves persist on disk).
set -eu
cd "$(dirname "$0")"

RUNTIME=${RUNTIME:-$(command -v podman >/dev/null 2>&1 && echo podman || echo docker)}
NAME=${NAME:-dgl}
PORT=${PORT:-2222}
HTTP_PORT=${HTTP_PORT:-8080}

# SELinux relabel suffix — needed for podman on SELinux hosts, rejected by Docker.
case "$RUNTIME" in
    *podman*) Z=":Z" ;;
    *)        Z=""   ;;
esac

if $RUNTIME inspect "$NAME" >/dev/null 2>&1; then
    echo "==> Removing existing container ($NAME)..."
    $RUNTIME rm -f "$NAME" >/dev/null
fi

echo "==> Starting $NAME (ssh: $PORT, http: $HTTP_PORT, runtime: $RUNTIME)..."
$RUNTIME run -d --name "$NAME" \
    --cap-add SYS_ADMIN \
    -p "$PORT:22" \
    -p "$HTTP_PORT:80" \
    -v "$(pwd)/runtime/dgldir:/var/dgl-chroot/dgldir$Z" \
    -v "$(pwd)/runtime/save:/var/dgl-chroot/usr/games/lib/nethackdir/save$Z" \
    -v "$(pwd)/runtime/bones:/var/dgl-chroot/usr/games/lib/nethackdir/bones$Z" \
    -v "$(pwd)/runtime/mail:/var/dgl-chroot/mail$Z" \
    -v "$(pwd)/runtime/ssh-keys:/etc/ssh/keys$Z" \
    dgl-nethack

echo "==> SSH: ssh -p $PORT nethack@localhost"
echo "==> HTTP: http://localhost:$HTTP_PORT"
