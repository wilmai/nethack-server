#!/bin/sh
# Container entrypoint: ensure persistent state, seed the dgl user db,
# bind-mount real /dev nodes into the chroot, then exec the CMD (sshd).
set -e

# Persistent ssh host keys (idempotent).
for t in ed25519 rsa; do
    k=/etc/ssh/keys/ssh_host_${t}_key
    [ -f "$k" ] || ssh-keygen -q -N "" -t "$t" -f "$k"
done

# Recreate expected subtree — host bind-mounts mask the image-staged dirs.
mkdir -p /var/dgl-chroot/dgldir/rcfiles \
         /var/dgl-chroot/dgldir/inprogress \
         /var/dgl-chroot/dgldir/userdata \
         /var/dgl-chroot/dgldir/extrainfo \
         /var/dgl-chroot/usr/games/lib/nethackdir/save \
         /var/dgl-chroot/usr/games/lib/nethackdir/bones \
         /var/dgl-chroot/mail
chown -R 5:60 /var/dgl-chroot/dgldir \
              /var/dgl-chroot/usr/games/lib/nethackdir/save \
              /var/dgl-chroot/usr/games/lib/nethackdir/bones \
              /var/dgl-chroot/mail
chmod 1777 /var/dgl-chroot/mail

# Seed the dgl user db on first boot.
DB=/var/dgl-chroot/dgldir/dgamelaunch.db
if [ ! -s "$DB" ]; then
    rm -f "$DB"
    sqlite3 "$DB" < /usr/local/share/dgl/schema.sql
    chown 5:60 "$DB"
fi

# Bind real /dev nodes onto the chroot's placeholders (mknod is
# denied under rootless podman, hence the bind dance).
for d in null zero urandom tty; do
    target=/var/dgl-chroot/dev/$d
    [ -e "$target" ] || : > "$target"
    mountpoint -q "$target" || mount --bind "/dev/$d" "$target"
done

mkdir -p /run/sshd
exec "$@"
