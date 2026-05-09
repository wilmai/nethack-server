# syntax=docker/dockerfile:1.7
#
# Minimal dgamelaunch + NetHack server.  Use ./setup.sh + ./run.sh, or:
#   podman build -t dgl-nethack .
#   podman run -d --cap-add SYS_ADMIN -p 2222:22 dgl-nethack
#   ssh -p 2222 nethack@localhost

# ============================================================================
# Builder stage — toolchain + sources, produces /out/{chroot,dgamelaunch}
# ============================================================================
FROM debian:stable-slim AS builder

ARG NH_VER=5.0.0
ARG NH_SHA256=2959b7886aac76185b90aea0c9f80d14343f604de0ae96b3dd2a760f7ab3bde9
ARG DGL_REPO=https://github.com/paxed/dgamelaunch.git
ARG DGL_REF=master

ENV DEBIAN_FRONTEND=noninteractive \
    CHROOT=/out/chroot

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential autoconf automake bison flex libfl-dev \
      libncurses-dev libsqlite3-dev pkg-config \
      curl ca-certificates git groff \
      ncurses-base ncurses-term libncursesw6 libtinfo6 libsqlite3-0 \
      dash ttyrec \
    && rm -rf /var/lib/apt/lists/*

# --- Build NetHack ----------------------------------------------------------
WORKDIR /tmp/build
COPY config/build-nethack.sh /tmp/build-nethack.sh
RUN NH_VER="${NH_VER}" NH_SHA256="${NH_SHA256}" sh /tmp/build-nethack.sh

# --- Build dgamelaunch ------------------------------------------------------
RUN git clone --depth=1 --branch ${DGL_REF} ${DGL_REPO} dgl
WORKDIR /tmp/build/dgl
COPY patches/dgl-quickplay.patch /tmp/patches/dgl-quickplay.patch
RUN git apply /tmp/patches/dgl-quickplay.patch
RUN ./autogen.sh \
    && ./configure --enable-sqlite --with-config-file=/etc/dgamelaunch.conf \
    && make -j1 dgamelaunch \
    && install -D -m 4755 -o root -g root dgamelaunch /out/dgamelaunch \
    && make -j1 CC="gcc -Wno-implicit-function-declaration -Wno-implicit-int -Wno-error=implicit-function-declaration -Wno-error=implicit-int -Wno-error=incompatible-pointer-types -Wno-error=int-conversion" ee \
    && install -D -m 0755 ee /usr/local/bin/ee

# --- Stage chroot tree at $CHROOT ------------------------------------------
COPY config/build-chroot.sh /tmp/build-chroot.sh
RUN sh /tmp/build-chroot.sh

# ============================================================================
# Runtime stage — sshd + dgamelaunch suid binary + staged chroot
# ============================================================================
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      openssh-server ca-certificates ncurses-base \
      libncursesw6 libtinfo6 libsqlite3-0 sqlite3 \
      nginx-light curl \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ARG TTYD_VER=1.7.7
RUN curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VER}/ttyd.x86_64" \
      -o /usr/local/bin/ttyd \
    && chmod 0755 /usr/local/bin/ttyd

COPY --from=builder /out/chroot       /var/dgl-chroot
COPY --from=builder /out/dgamelaunch  /usr/local/bin/dgamelaunch
RUN chmod 4755 /usr/local/bin/dgamelaunch

COPY config/dgamelaunch.conf         /etc/dgamelaunch.conf
COPY config/dgamelaunch-schema.sql   /usr/local/share/dgl/schema.sql
COPY config/dgl-banner               /var/dgl-chroot/dgl-banner
COPY config/dgl_menu_anon.txt        /var/dgl-chroot/dgl_menu_anon.txt
COPY config/dgl_menu_user.txt        /var/dgl-chroot/dgl_menu_user.txt
COPY config/dgl-default.nethackrc    /var/dgl-chroot/dgl-default.nethackrc

RUN install -d -m 0755 /etc/ssh/keys
COPY config/sshd-dgl.conf /etc/ssh/sshd_config.d/dgl.conf

RUN useradd -m -s /usr/local/bin/dgamelaunch nethack \
    && passwd -d nethack

COPY config/dgl-init.sh /usr/local/bin/dgl-init
RUN chmod +x /usr/local/bin/dgl-init

COPY config/ttyd-dgl-launch.sh /usr/local/bin/ttyd-dgl-launch
RUN chmod +x /usr/local/bin/ttyd-dgl-launch

COPY config/nginx-ttyd.conf /etc/nginx/nginx.conf

EXPOSE 22 80

# Persistent state.  save/bones are split out of HACKDIR so they don't
# mask the level/data files inside it.
VOLUME ["/var/dgl-chroot/dgldir", \
        "/var/dgl-chroot/usr/games/lib/nethackdir/save", \
        "/var/dgl-chroot/usr/games/lib/nethackdir/bones", \
        "/var/dgl-chroot/mail", \
        "/etc/ssh/keys"]

ENTRYPOINT ["/usr/local/bin/dgl-init"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
