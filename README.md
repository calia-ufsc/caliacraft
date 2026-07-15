# caliacraft

Servidor de Minecraft (NeoForge 1.21.1) para ambientes Linux sem acesso root.

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
cp .env.example .env   # ou: envow generate
# edite o .env conforme necessário
bash bootstrap.sh
```

## Configuração

Todas as opções ficam no `.env`. O schema completo está em [`envow.toml`](envow.toml) — use `envow generate` para regenerar o `.env.example` e `envow validate` para checar antes de subir o servidor.

| Seção | Variável | Padrão | Descrição |
|---|---|---|---|
| directories | `DATA_DIR` | `~/data` | Raiz dos dados persistentes |
| directories | `BIN_DIR` | `~/bin` | Diretório de binários do usuário |
| java | `JAVA_URL` | Zulu JDK 21.0.7 | URL do tarball do JDK |
| tools | `JUST_VERSION` | `1.56.0` | Versão do just |
| tools | `PLAYIT_VERSION` | `0.15.26` | Versão do playit |
| tools | `FRP_VERSION` | `0.70.0` | Versão do frp |
| minecraft | `NEOFORGE_VERSION` | `21.1.233` | Versão do NeoForge (MC 1.21.1) |
| minecraft | `SERVER_PACK_URL` | — | ZIP do server pack do CurseForge |
| minecraft | `MC_RAM_MIN` | `4G` | Heap mínimo da JVM (-Xms) |
| minecraft | `MC_RAM_MAX` | `12G` | Heap máximo da JVM (-Xmx) |
| tunnel | `TUNNEL_MODE` | `frp` | `frp` ou `playit` |
| tunnel | `FRP_SERVER_ADDR` | — | IP/host do servidor frps |
| tunnel | `FRP_TOKEN` | — | Token de autenticação frp |

## Comandos

### Setup

```
just bootstrap          # valida o .env e executa os scripts 01–05 em sequência (executar uma vez)
```

### Servidor

```
just mc-up              # inicia o servidor em background (nohup)
just mc-down            # para o servidor
just mc-logs            # acompanha o log do servidor
just mc-status          # verifica se o servidor está rodando
just mc-start           # inicia o servidor em primeiro plano (útil para debug)
```

### Túnel

```
just tunnel-playit         # inicia o túnel playit.gg em background (nohup)
just tunnel-playit-logs    # acompanha o log do playit (siga a URL de claim na primeira vez)
just tunnel-playit-down    # para o túnel playit.gg
just tunnel-frp-up         # inicia o túnel frp em background (nohup)
just tunnel-frp-down       # para o túnel frp
just tunnel-frp-logs       # acompanha o log do túnel frp
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
Requer um VPS com frps rodando. Preencha `FRP_SERVER_ADDR` e `FRP_TOKEN` no `.env`.

```bash
just tunnel-frp-up
```

## Observações

- `online-mode` está desativado por padrão — necessário para launchers não-oficiais
- O Java 21 é instalado localmente em `$DATA_DIR/jdk`, sem alterar o Java do sistema
- Os JVM args ficam em `$DATA_DIR/minecraft/user_jvm_args.txt` — editável sem rebootstrap
- Processos em background usam `nohup` — PIDs e logs ficam em `$DATA_DIR/run/`
- Todos os binários vão para `$BIN_DIR` — nenhum comando requer sudo
