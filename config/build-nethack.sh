#!/bin/sh
# Build NetHack from upstream source and install into /usr.
# Run from /tmp/build in the builder stage.  Expects:
#   NH_VER     — version string, e.g. "5.0.0"
#   NH_SHA256  — sha256 of the source tarball
set -eux

NH_V=$(echo "${NH_VER}" | tr -d '.')
curl -fsSLo nh.tgz "https://www.nethack.org/download/${NH_VER}/nethack-${NH_V}-src.tgz"
echo "${NH_SHA256}  nh.tgz" | sha256sum -c -
tar xzf nh.tgz && rm nh.tgz

cd "NetHack-${NH_VER}"
sed -i 's@^PREFIX=.*@PREFIX=/usr@' "sys/unix/hints/linux.${NH_V}"
# Enable in-game mail.
sed -i 's@^/\* #define SIMPLE_MAIL \*/@#define SIMPLE_MAIL@' include/unixconf.h
grep -q '^#define SIMPLE_MAIL' include/unixconf.h
sh sys/unix/setup.sh "sys/unix/hints/linux.${NH_V}"
make fetch-lua
make WANT_WIN_TTY=1 WANT_WIN_CURSES=1 -j"$(nproc)" all
make WANT_WIN_TTY=1 WANT_WIN_CURSES=1 install
