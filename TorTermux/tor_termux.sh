#!/data/data/com.termux/files/usr/bin/bash

# ==============================================
# INSTALADOR TOR PARA TERMUX - VERSÃO OTIMIZADA
# ==============================================

# Cores melhoradas (visíveis em todos os terminais)
RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[94m'
NC='\e[0m'

# Funções de mensagem robustas
error() { echo -e "${RED}[✘]${NC} $1" >&2; exit 1; }
success() { echo -e "${GREEN}[✔]${NC} $1"; }
info() { echo -e "${BLUE}[*]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Verificação completa do ambiente Termux
verify_environment() {
    if ! command -v termux-setup-storage >/dev/null 2>&1; then
        error "Este script requer Termux (Android)"
    fi
    if [ ! -d "$PREFIX" ]; then
        error "Diretório do Termux não encontrado"
    fi
}

# Instalação com tratamento de erros aprimorado
install_packages() {
    info "Atualizando repositórios..."
    pkg update -y || error "Falha ao atualizar pacotes"
    info "Instalando pacotes essenciais..."
    for pkg in tor torsocks curl; do
        if ! command -v $pkg >/dev/null 2>&1; then
            pkg install -y $pkg || error "Falha ao instalar $pkg"
        fi
    done
}

# Configuração avançada do Tor
configure_tor() {
    TOR_DIR="$HOME/.tor"
    mkdir -p "$TOR_DIR" || error "Falha ao criar $TOR_DIR"
    
    info "Criando configuração personalizada..."
    cat > "$TOR_DIR/torrc" <<'EOF'
SocksPort 127.0.0.1:9050
ControlPort 127.0.0.1:9051
CookieAuthentication 1
AvoidDiskWrites 1
ClientOnly 1
UseBridges 0
ConnectionPadding 1
CircuitBuildTimeout 60
KeepalivePeriod 60
Log notice file /data/data/com.termux/files/home/.tor/tor.log
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
DNSPort 5353
EOF
}

# Controle de serviço melhorado
manage_tor_service() {
    info "Gerenciando serviço Tor..."
    termux-wake-lock
    
    if pgrep -x "tor" >/dev/null; then
        warning "Tor já em execução - reiniciando..."
        pkill tor && sleep 2
    fi
    nohup tor -f "$TOR_DIR/torrc" > "$TOR_DIR/tor.log" 2>&1 &
    
    local timeout=30
    local start_time=$(date +%s)
    while ! grep -q "Bootstrapped 100%" "$TOR_DIR/tor.log" 2>/dev/null; do
        sleep 1
        if [ $(($(date +%s) - start_time)) -gt $timeout ]; then
            error "Timeout na inicialização do Tor"
            tail -n 10 "$TOR_DIR/tor.log" >&2
            exit 1
        fi
    done
}

# Verificação de conexão completa
verify_connection() {
    info "Verificando conexão Tor..."
    for ((i=1; i<=3; i++)); do
        if torsocks curl -s --connect-timeout 20 https://check.torproject.org/api/ip | grep -q '"IsTor":true'; then
            local tor_ip=$(torsocks curl -s https://check.torproject.org/api/ip | grep -oP '(?<="Ip":")[^"]+')
            success "Conexão Tor estabelecida! IP: $tor_ip"
            return 0
        fi
        warning "Tentativa $i/3 falhou - tentando novamente..."
        sleep 5
    done
    error "Falha ao verificar conexão Tor"
}

# Menu interativo melhorado
show_menu() {
    echo -e "\n${GREEN}=== CONTROLE DO TOR ==="
    echo -e "${YELLOW}1.${NC} Verificar status: tail -f ~/.tor/tor.log"
    echo -e "${YELLOW}2.${NC} Testar conexão: torsocks curl https://check.torproject.org"
    echo -e "${YELLOW}3.${NC} Parar Tor: pkill tor"
    echo -e "${YELLOW}4.${NC} Reiniciar Tor: pkill tor && tor -f ~/.tor/torrc"
    echo -e "${YELLOW}5.${NC} Desinstalar Tor: pkg remove tor -y"
    echo -e "${GREEN}======================${NC}"
}

# Fluxo principal
main() {
    clear
    echo -e "${BLUE}=== INSTALADOR TOR PARA TERMUX ===${NC}"
    verify_environment
    install_packages
    configure_tor
    manage_tor_service
    verify_connection
    show_menu
    success "Instalação concluída em $(date +'%T')"
}

# Execução
eval "$(basename "$0")" == "bash" && main || chmod +x "$0" && main

