# caliacraft

Servidor de Minecraft (PaperMC) para ambientes Linux sem acesso root.

Roda como um processo Java comum, com playit.gg ou frp para acesso externo. Sem Docker, sem sudo.

## Requisitos

- Linux x86-64
- Python 3
- tmux
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

```
just bootstrap       # instala Java 25, PaperMC, playit e frpc (executar uma vez)
just up              # sobe o servidor em background e indica como iniciar o túnel
just down            # para tudo
just status          # mostra o status dos serviços
just mc-start        # inicia o servidor em primeiro plano (útil para debug)
just mc-up           # inicia o servidor em background (tmux)
just mc-down         # para o servidor graciosamente
just mc-console      # abre o console do servidor (Ctrl+B D para sair)
just tunnel-playit   # inicia o túnel pelo playit.gg (siga a URL exibida no terminal)
just tunnel-frp      # inicia o túnel frp em primeiro plano
just tunnel-frp-up   # inicia o túnel frp em background (tmux)
just tunnel-frp-down # para o túnel frp
```

## Túnel

### playit.gg (recomendado)
Gratuito, sem servidor próprio. Região São Paulo disponível no plano pago (~$3/mês).

```bash
just tunnel-playit
# siga a URL de claim exibida no terminal para registrar o agente
```

### frp (auto-hospedado)
Requer um VPS com frps rodando. Edite `~/.config/frp/frpc.toml` com os dados do seu servidor.

```bash
just tunnel-frp-up
```

## Observações

- `online-mode` está desativado por padrão — necessário para launchers não-oficiais
- O Java 25 é instalado localmente em `$DATA_DIR/jdk`, sem alterar o Java do sistema
- Todos os binários vão para `$BIN_DIR` — nenhum comando requer sudo
