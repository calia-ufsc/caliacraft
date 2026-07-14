# caliacraft

Minecraft server provisioning for restricted Linux environments without root access (JupyterHub, university clusters, etc.).

Runs PaperMC as a plain Java process with playit.gg or frp for external access. No Docker, no sudo.

## Requirements

- Linux x86-64
- Python 3 (for the PaperMC download step)
- tmux
- curl
- Outbound internet on at least one of: 80, 443, 8080, 8443

## Setup

```bash
git clone https://github.com/calia-ufsc/caliacraft
cd caliacraft
cp .env.example .env
# edit .env — set DATA_DIR to a persistent path if needed
bash bootstrap.sh
```

## Configuration

All config lives in `.env`:

| Variable | Default | Description |
|---|---|---|
| `DATA_DIR` | `~/data` | Where Minecraft data and JDK are stored — point to persistent storage |
| `BIN_DIR` | `~/bin` | Where binaries are installed |
| `PAPER_VERSION` | `26.2` | Minecraft / PaperMC version |
| `MC_RAM_MIN` | `2G` | JVM min heap |
| `MC_RAM_MAX` | `8G` | JVM max heap |
| `TUNNEL_MODE` | `playit` | `playit` or `frp` |

On JupyterHub (UFSC): set `DATA_DIR=$HOME/privado/caliacraft`.

## Commands

```
just bootstrap      # install Java 25, PaperMC, playit, frpc (run once)
just up             # start Minecraft in background
just down           # stop everything
just status         # show service status
just mc-console     # attach to Minecraft console (Ctrl+B D to detach)
just tunnel-playit  # start playit.gg tunnel (follow the claim URL)
just tunnel-frp-up  # start frp tunnel in background
```

## Tunnel

### playit.gg (recommended for beginners)
Free tier works, no server needed. São Paulo region available on paid (~$3/mo).

```bash
just tunnel-playit
# follow the claim URL printed in the terminal
```

### frp (self-hosted)
Requires a VPS running frps. Edit `~/.config/frp/frpc.toml` with your server details.

```bash
just tunnel-frp-up
```

## Notes

- `online-mode` is set to `false` by default (required for unofficial launchers)
- Java 25 is installed locally to `$DATA_DIR/jdk` — system Java is not used or modified
- All binaries go to `$BIN_DIR` — no sudo required at any point
