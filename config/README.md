# config/

Files baked into the image at build time.

## dgamelaunch / NetHack

- `dgamelaunch.conf` — game definitions, menus, paths.  Read **pre-chroot**.
- `dgl-banner`, `dgl_menu_anon.txt`, `dgl_menu_user.txt` — menu UI.  Read **post-chroot**.
- `dgamelaunch-schema.sql` — sqlite schema, applied on first boot.
- `dgl-default.nethackrc` — rcfile template, copied into a player's profile on first edit.

## sshd

- `sshd-dgl.conf` — sshd drop-in: pins host-key paths, forces `nethack` into dgl.

## Build / runtime scripts

- `build-nethack.sh` — download, sha256-verify, build, install NetHack.  Reads `NH_VER` / `NH_SHA256`.
- `build-chroot.sh` — stage the chroot tree at `$CHROOT` (binaries, terminfo, libs, NSS, dev placeholders).
- `dgl-init.sh` — entrypoint: ssh keys, volume dirs, dgl db seed, bind-mount `/dev`, exec CMD.
