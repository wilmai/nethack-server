#!/bin/sh
# Stage the dgamelaunch chroot tree at $CHROOT.
set -eux

mkdir -p \
    ${CHROOT}/bin ${CHROOT}/usr/bin ${CHROOT}/usr/games/lib \
    ${CHROOT}/dev ${CHROOT}/tmp ${CHROOT}/mail \
    ${CHROOT}/dgldir/rcfiles  ${CHROOT}/dgldir/inprogress \
    ${CHROOT}/dgldir/userdata ${CHROOT}/dgldir/extrainfo
chmod 1777 ${CHROOT}/tmp ${CHROOT}/mail

cp    /usr/games/nethack           ${CHROOT}/usr/games/nethack
cp -a /usr/games/lib/nethackdir    ${CHROOT}/usr/games/lib/

# sysconf ships 0600 root; world-readable is fine (it's static config).
chmod 0644 ${CHROOT}/usr/games/lib/nethackdir/sysconf

# Hand games ownership of HACKDIR's mutable state files; data files
# (binary, nhdat, level archives) stay root-owned read-only.
chown 5:60 ${CHROOT}/usr/games/lib/nethackdir/record \
           ${CHROOT}/usr/games/lib/nethackdir/logfile \
           ${CHROOT}/usr/games/lib/nethackdir/livelog \
           ${CHROOT}/usr/games/lib/nethackdir/xlogfile \
           ${CHROOT}/usr/games/lib/nethackdir/perm \
           ${CHROOT}/usr/games/lib/nethackdir/save

[ -d ${CHROOT}/usr/games/lib/nethackdir/bones ] \
   || mkdir ${CHROOT}/usr/games/lib/nethackdir/bones
chown 5:60 ${CHROOT}/usr/games/lib/nethackdir/bones

# NetHack writes per-game level files + locks in HACKDIR itself
# the dir must be games-writable.
chown 5:60 ${CHROOT}/usr/games/lib/nethackdir

cp    /bin/dash                    ${CHROOT}/bin/sh
cp    /bin/grep                    ${CHROOT}/bin/grep
cp    /bin/gzip                    ${CHROOT}/bin/gzip
cp    /usr/bin/ttyrec              ${CHROOT}/usr/bin/ttyrec
cp    /usr/local/bin/ee            ${CHROOT}/usr/bin/ee

# terminfo for ncurses apps (nethack, ee).
for d in /etc/terminfo /lib/terminfo /usr/share/terminfo; do
    [ -d "$d" ] && { mkdir -p "${CHROOT}$(dirname "$d")"; cp -a "$d" "${CHROOT}$d"; }
done

# ldd-walk every chroot binary, copy each .so to its absolute path.
for bin in ${CHROOT}/bin/sh \
           ${CHROOT}/bin/grep \
           ${CHROOT}/bin/gzip \
           ${CHROOT}/usr/bin/ttyrec \
           ${CHROOT}/usr/bin/ee \
           ${CHROOT}/usr/games/nethack \
           ${CHROOT}/usr/games/lib/nethackdir/nethack \
           ${CHROOT}/usr/games/lib/nethackdir/recover; do
    ldd "$bin" | awk '{ for (i=1;i<=NF;i++) if ($i ~ /^\//) print $i }'
done | sort -u | while read -r lib; do
    mkdir -p "${CHROOT}$(dirname "$lib")"
    cp -L "$lib" "${CHROOT}$lib"
done

chown -R 5:60 ${CHROOT}/dgldir ${CHROOT}/mail

# Minimal NSS so getpwuid(5) returns a record for `games` inside the
# chroot.  Without it, NetHack's mail.c:117 dereferences NULL on init.
mkdir -p ${CHROOT}/etc
printf 'root:x:0:0::/:/bin/sh\ngames:x:5:60::/var/games:/bin/sh\n' \
    > ${CHROOT}/etc/passwd
printf 'root:x:0:\ngames:x:60:\n' > ${CHROOT}/etc/group
printf 'passwd: files\ngroup: files\n' > ${CHROOT}/etc/nsswitch.conf
cp -L /lib/$(uname -m)-linux-gnu/libnss_files.so.2 \
      ${CHROOT}/lib/$(uname -m)-linux-gnu/libnss_files.so.2

# Placeholders; dgl-init bind-mounts real device nodes on top.
touch ${CHROOT}/dev/null ${CHROOT}/dev/zero \
      ${CHROOT}/dev/urandom ${CHROOT}/dev/tty
