# nethack-server

Containerized [NetHack](https://www.nethack.org/) server fronted by
[dgamelaunch](https://github.com/paxed/dgamelaunch), reachable over SSH.

## Quick start

```sh
./setup.sh        # build the image and create runtime/ state dirs
./run.sh          # start the container on port 2222

ssh -p 2222 nethack@localhost
```

## What's in the image

- Debian stable-slim, multi-stage build.
- NetHack from upstream source.
- dgamelaunch (paxed fork) with sqlite.
- OpenSSH entry-point.
- Self-contained chroot at `/var/dgl-chroot`.

## Persistent state

`run.sh` bind-mounts these under `./runtime/`; they
survive image rebuilds.

| Host path           | Purpose                                       |
| ------------------- | --------------------------------------------- |
| `runtime/dgldir/`   | dgl user db, rcfiles, ttyrecs, per-user data  |
| `runtime/save/`     | NetHack save files                            |
| `runtime/bones/`    | Shared bones files                            |
| `runtime/mail/`     | In-game mail spool                            |
| `runtime/ssh-keys/` | SSH host keys (stable across rebuilds)        |

## Configuration

See [`config/`](config/README.md) for the file-by-file breakdown.

## License

MIT — see [LICENSE](LICENSE).
