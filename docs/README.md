# vlab

Provisioning for the UFSC JupyterHub research cluster (`150.162.7.35`).

## Environment

- Platform: JupyterHub (managed, no root, no containers)
- User: `jovyan` (shared container user, OAuth login)
- Persistent storage: `~/privado` (29TB, survives restarts)
- RAM: 2TB total, ~477GB free
- Outbound ports allowed: 80, 443, 8080, 8443

## Setup

Run once after a fresh session:

```bash
git clone https://github.com/mbandeira/vlab ~/privado/vlab
cd ~/privado/vlab
bash bootstrap.sh
```

## Commands

```
just bootstrap     # install all dependencies (run once)
just up            # start Minecraft server in background
just down          # stop everything
just status        # show service status
just mc-console    # attach to Minecraft console
just tunnel-playit # start playit.gg tunnel (interactive)
just tunnel-frp-up # start frp tunnel in background
```

## Tunnel

Two tunnel options for external access:

### playit.gg (recommended)
Free tier works. Run `just tunnel-playit` and follow the claim URL.
Address format: `something.gl.joinmc.link`

### frp (self-hosted)
Requires a VPS running frps. Fill in `~/.config/frp/frpc.toml` with server details.

## Notes

- `~/home/jovyan` is ephemeral — always work from `~/privado`
- Java 25 installed to `~/privado/jdk25` (not system Java)
- Binaries installed to `~/bin` (no sudo needed)
- Session restarts require re-exporting PATH or opening a new terminal (`.bashrc` handles this)
