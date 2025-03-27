#!/data/data/com.termux/files/usr/bin/bash

# ==============================================
# INSTALADOR TOR PARA TERMUX - MÉTODO CORRETO
# ==============================================

# Cores para melhor visualização
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# Funções de mensagem
info() { echo -e "${BLUE}[*]${NC} $1"; }
success() { echo -e "${GREEN}[✔]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✘]${NC} $1" >&2; }

# Verificar se é Termux
if ! command -v termux-setup-storage >/dev/null 2>&1; then
    error "Este script deve ser executado no Termux (Android)"
    exit 1
fi

# Método de instalação seguro
install_tor() {
    info "Atualizando pacotes..."
    pkg update -y && pkg upgrade -y >/dev/null 2>&1 || {
        error "Falha na atualização"
        exit 1
    }

    if ! command -v tor >/dev/null 2>&1; then
        info "Instalando Tor..."
        pkg install -y tor torsocks >/dev/null 2>&1 || {
            error "Falha na instalação"
            exit 1
        }
        success "Tor instalado"
    else
        info "Tor já instalado (v$(tor --version | awk '{print $3}'))"
    fi

    # Configuração
    TOR_DIR="$HOME/.tor"
    mkdir -p "$TOR_DIR" || {
        error "Falha ao criar diretório"
        exit 1
    }

    cat > "$TOR_DIR/torrc" <<'EOF'
SocksPort 127.0.0.1:9050
ControlPort 127.0.0.1:9051
CookieAuthentication 1
Log notice file /data/data/com.termux/files/home/.tor/tor.log
AvoidDiskWrites 1
EOF

    # Inicialização
    if ! pgrep -x "tor" >/dev/null; then
        info "Iniciando Tor..."
        nohup tor -f "$TOR_DIR/torrc" >/dev/null 2>&1 &
        sleep 5
    fi

    # Verificação
    TOR_IP=$(torsocks curl -s https://check.torproject.org/api/ip | grep -oP '(?<="Ip":")[^"]+')
    [ -n "$TOR_IP" ] && success "Conectado! IP Tor: $TOR_IP" || {
        error "Falha na conexão"
        tail -n 5 "$TOR_DIR/tor.log" >&2
        exit 1
    }
}

# Execução principal
if [ "$0" = "bash" ]; then
    warning "Script executado via pipe - instalando diretamente"
    install_tor
else
    # Se executado localmente, faz auto-configuração
    chmod +x "$0" 2>/dev/null
    install_tor
fi

echo -e "\n${GREEN}Use:${NC} torsocks antes de qualquer comando para usar o Tor"
info "Exemplo: torsocks curl https://check.torproject.org"
echo -e "${YELLOW}3.${NC} Monitorar logs: tail -f $TOR_DIR/tor.log"
echo -e "${YELLOW}4.${NC} Parar Tor: pkill tor"
echo -e "${YELLOW}5.${NC} Reiniciar Tor: pkill tor && tor -f $TOR_DIR/torrc"

success "Instalação concluída! Execute novamente este script para verificar o status."
