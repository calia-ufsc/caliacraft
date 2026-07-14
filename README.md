# caliacraft

Servidor de Minecraft (PaperMC) para ambientes Linux sem acesso root.

Roda como um processo Java comum, com playit.gg ou frp para acesso externo. Sem Docker, sem sudo.

## Requisitos

- Linux x86-64
- Python 3
- zstd
- curl
- Acesso à internet nas portas 80, 443, 8080 ou 8443

## Instalação

```bash
git clone https://github.com/calia-ufsc/caliacraft
cd caliacraft
cp .env.example .env
# edite o .env conforme necessário
bash bootstrap.sh
```

## Configuração

Todas as opções ficam no `.env`:

| Variável | Padrão | Descrição |
|---|---|---|
| `DATA_DIR` | `~/data` | Onde os dados do servidor e o JDK são armazenados — aponte para um diretório persistente se necessário |
| `BIN_DIR` | `~/bin` | Onde os binários são instalados |
| `PAPER_VERSION` | `26.2` | Versão do Minecraft / PaperMC |
| `MC_RAM_MIN` | `2G` | Heap mínimo da JVM |
| `MC_RAM_MAX` | `8G` | Heap máximo da JVM |

## Comandos

### Setup

```
just bootstrap          # instala Java 25, PaperMC, tmux, playit e frpc (executar uma vez)
```

### Servidor

```
just mc-up              # inicia o servidor em background (tmux)
just mc-down            # para o servidor graciosamente
just mc-console         # abre o console do servidor (Ctrl+B D para sair)
just mc-status          # verifica se o servidor está rodando
just mc-start           # inicia o servidor em primeiro plano (útil para debug)
```

### Túnel

```
just tunnel-playit         # inicia o túnel playit.gg em background (tmux)
just tunnel-playit-console # abre o console do playit (siga a URL de claim na primeira vez)
just tunnel-playit-down    # para o túnel playit.gg
just tunnel-frp-up         # inicia o túnel frp em background (tmux)
just tunnel-frp-down       # para o túnel frp
just tunnel-frp-console    # abre o console do túnel frp (Ctrl+B D para sair)
just tunnel-frp            # inicia o túnel frp em primeiro plano (útil para debug)
```

### Stack completa

```
just up                 # sobe o servidor em background e exibe opções de túnel
just down               # para o servidor e todos os túneis
just status             # mostra o status de todos os serviços
```

## Túnel

### playit.gg (recomendado)
Gratuito, sem servidor próprio. Região São Paulo disponível no plano pago (~$3/mês).

```bash
just tunnel-playit
just tunnel-playit-console  # abra para ver e seguir a URL de claim na primeira vez
```

### frp (auto-hospedado)
Requer um VPS com frps rodando. Edite `~/.config/frp/frpc.toml` com os dados do seu servidor.

```bash
just tunnel-frp-up
```

## Observações

- `online-mode` está desativado por padrão — necessário para launchers não-oficiais
- O Java 25 é instalado localmente em `$DATA_DIR/jdk`, sem alterar o Java do sistema
- O tmux é instalado localmente em `$BIN_DIR`, sem alterar o tmux do sistema
- Todos os binários vão para `$BIN_DIR` — nenhum comando requer sudo
