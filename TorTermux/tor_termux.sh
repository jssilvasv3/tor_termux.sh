#!/data/data/com.termux/files/usr/bin/bash

# ==============================================
# INSTALADOR TOR PARA TERMUX - VERSÃO OTIMIZADA
# ==============================================

# Cores melhoradas
RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[94m'
NC='\e[0m'

# Funções de mensagens
error() { echo -e "${RED}[✘]${NC} $1" >&2; exit 1; }
success() { echo -e "${GREEN}[✔]${NC} $1"; }
info() { echo -e "${BLUE}[*]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Verificação do ambiente Termux
verify_environment() {
    if ! command -v termux-setup-storage >/dev/null 2>&1; then
        error "Este script requer Termux (Android)"
    fi
    if [ ! -d "$PREFIX" ]; then
        error "Diretório do Termux não encontrado"
    fi
}

# Instalação de pacotes necessários
install_packages() {
    info "Atualizando repositórios..."
    pkg update -y || error "Falha na atualização"
    info "Instalando pacotes essenciais..."
    pkg install -y tor torsocks curl || error "Falha na instalação de pacotes"
}

# Configuração personalizada do Tor
configure_tor() {
    TOR_DIR="$HOME/.tor"
    mkdir -p "$TOR_DIR" || error "Falha ao criar diretório do Tor"

    info "Criando arquivo de configuração..."
    cat > "$TOR_DIR/torrc" <<EOF
SocksPort 127.0.0.1:9050
ControlPort 127.0.0.1:9051
CookieAuthentication 1
AvoidDiskWrites 1
ClientOnly 1
UseBridges 0
ConnectionPadding 1
CircuitBuildTimeout 60
KeepalivePeriod 60
Log notice file $TOR_DIR/tor.log
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
DNSPort 5353
EOF
}

# Inicia o serviço Tor e gerencia logs
manage_tor_service() {
    info "Gerenciando serviço Tor..."
    pkill tor 2>/dev/null && sleep 2
    nohup tor -f "$TOR_DIR/torrc" > "$TOR_DIR/tor.log" 2>&1 &
    termux-wake-lock
    sleep 10
    
    if ! grep -q "Bootstrapped 100%" "$TOR_DIR/tor.log" 2>/dev/null; then
        warning "Tor falhou na inicialização. Tentando com bridges..."
        sed -i 's/UseBridges 0/UseBridges 1/' "$TOR_DIR/torrc"
        echo "Bridge obfs4 192.99.63.70:443 1234567890ABCDEF1234567890ABCDEF12345678 cert=ABCDEFGHIJKLMN iat-mode=0" >> "$TOR_DIR/torrc"
        nohup tor -f "$TOR_DIR/torrc" > "$TOR_DIR/tor.log" 2>&1 &
        sleep 10
    fi
    
    if ! grep -q "Bootstrapped 100%" "$TOR_DIR/tor.log" 2>/dev/null; then
        error "Falha ao conectar ao Tor. Verifique sua conexão ou tente outro bridge."
    fi
}

# Testa conexão via Tor
verify_connection() {
    info "Verificando conexão Tor..."
    if torsocks curl -s https://check.torproject.org/api/ip | grep -q '"IsTor":true'; then
        local tor_ip=$(torsocks curl -s https://check.torproject.org/api/ip | grep -oP '(?<="Ip":")[^"]+')
        success "Conexão Tor estabelecida! IP: $tor_ip"
    else
        error "Falha ao verificar conexão Tor."
    fi
}

# Menu interativo
show_menu() {
    echo -e "\n${GREEN}=== CONTROLE DO TOR ==="
    echo -e "${YELLOW}1.${NC} Verificar logs: tail -f ~/.tor/tor.log"
    echo -e "${YELLOW}2.${NC} Testar conexão: torsocks curl https://check.torproject.org"
    echo -e "${YELLOW}3.${NC} Parar Tor: pkill tor"
    echo -e "${YELLOW}4.${NC} Reiniciar Tor: pkill tor && tor -f ~/.tor/torrc"
    echo -e "${YELLOW}5.${NC} Desinstalar Tor: pkg remove tor -y"
    echo -e "${GREEN}======================${NC}"
}

# Execução principal
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

# Executa o script
main


