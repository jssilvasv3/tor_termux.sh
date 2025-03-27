#!/data/data/com.termux/files/usr/bin/bash

# ==============================================
# INSTALADOR AUTOMÁTICO DO TOR PARA TERMUX
# ==============================================

# Auto-configuração do script
SCRIPT_NAME="${0##*/}"
chmod +x "$SCRIPT_NAME" 2>/dev/null || {
    echo "[!] Erro ao dar permissões executáveis ao script" >&2
    exit 1
}

# Cores para melhor visualização
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# Função para exibir mensagens formatadas
info() { echo -e "${BLUE}[*]${NC} $1"; }
success() { echo -e "${GREEN}[✔]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✘]${NC} $1" >&2; }

# Verificar se é Termux
if ! command -v termux-setup-storage >/dev/null 2>&1; then
    error "Este script deve ser executado no Termux (Android)"
    exit 1
fi

# Atualização silenciosa
info "Atualizando pacotes..."
pkg update -y && pkg upgrade -y >/dev/null 2>&1 || {
    error "Falha na atualização dos pacotes"
    exit 1
}

# Instalação do Tor com verificação
if ! command -v tor >/dev/null 2>&1; then
    info "Instalando Tor..."
    pkg install -y tor torsocks >/dev/null 2>&1 || {
        error "Falha na instalação do Tor"
        exit 1
    }
    success "Tor instalado com sucesso"
else
    info "Tor já instalado (v$(tor --version | awk '{print $3}'))"
fi

# Configuração segura
TOR_DIR="$HOME/.tor"
mkdir -p "$TOR_DIR" || {
    error "Falha ao criar diretório de configuração"
    exit 1
}

cat > "$TOR_DIR/torrc" <<'EOF'
SocksPort 127.0.0.1:9050
ControlPort 127.0.0.1:9051
CookieAuthentication 1
Log notice file /data/data/com.termux/files/home/.tor/tor.log
AvoidDiskWrites 1
HardwareAccel 0
EOF

# Inicialização inteligente
info "Iniciando serviço Tor..."
if pgrep -x "tor" >/dev/null; then
    warning "Tor já está em execução (PID: $(pgrep tor))"
else
    nohup tor -f "$TOR_DIR/torrc" >/dev/null 2>&1 &
    sleep 7  # Tempo de inicialização ajustado para Android
fi

# Verificação avançada
verify_tor() {
    local tor_ip
    tor_ip=$(torsocks curl -s https://check.torproject.org/api/ip | grep -oP '(?<="Ip":")[^"]+')
    
    if [ -n "$tor_ip" ]; then
        success "Conexão Tor estabelecida!"
        info "IP Tor: $tor_ip"
        info "Config: $TOR_DIR/torrc"
        info "Logs: $TOR_DIR/tor.log"
    else
        error "Falha na conexão Tor"
        tail -n 5 "$TOR_DIR/tor.log" >&2
        exit 1
    fi
}

verify_tor

# Menu pós-instalação
echo -e "\n${GREEN}=== COMANDOS ÚTEIS ===${NC}"
echo -e "${YELLOW}1.${NC} Testar conexão: torsocks curl -s https://check.torproject.org"
echo -e "${YELLOW}2.${NC} Acessar .onion: torsocks curl -s http://exemplo.onion"
echo -e "${YELLOW}3.${NC} Monitorar logs: tail -f $TOR_DIR/tor.log"
echo -e "${YELLOW}4.${NC} Parar Tor: pkill tor"
echo -e "${YELLOW}5.${NC} Reiniciar Tor: pkill tor && tor -f $TOR_DIR/torrc"

success "Instalação concluída! Execute novamente este script para verificar o status."
