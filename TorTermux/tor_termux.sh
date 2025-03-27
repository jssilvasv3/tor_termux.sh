#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# INSTALADOR TOR PARA TERMUX - VERSÃO OTIMIZADA
# ==========================================

RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[94m'
NC='\e[0m'

erro() { echo -e "${RED}[✘]${NC} $1" >&2; exit 1; }
sucesso() { echo -e "${GREEN}[✔]${NC} $1"; }
info() { echo -e "${BLUE}[*]${NC} $1"; }
aviso() { echo -e "${YELLOW}[!]${NC} $1"; }

verify_environment() {
    command -v termux-setup-storage >/dev/null 2>&1 || erro "Este script requer Termux."
    [ -d "$PREFIX" ] || erro "Diretório do Termux não encontrado."
}

install_packages() {
    info "Atualizando repositórios..."
    pkg update -y || erro "Falha na atualização de pacotes."
    
    info "Instalando pacotes essenciais..."
    for pkg in tor torsocks curl; do
        command -v $pkg >/dev/null 2>&1 || pkg install -y $pkg || erro "Falha ao instalar $pkg"
    done
}

configure_tor() {
    TOR_DIR="$HOME/.tor"
    mkdir -p "$TOR_DIR" || erro "Falha ao criar $TOR_DIR"
    
    cat > "$TOR_DIR/torrc" <<'EOF'
SocksPort 127.0.0.1:9052
ControlPort 127.0.0.1:9053
CookieAuthentication 1
AvoidDiskWrites 1
ClientOnly 1
UseBridges 0
Bridge obfs4 37.218.245.50:443 0123456789ABCDEF1234567890ABCDEF12345678
ConnectionPadding 1
CircuitBuildTimeout 60
KeepalivePeriod 60
Log notice file /data/data/com.termux/files/home/.tor/tor.log
EOF
    chmod 600 "$TOR_DIR/torrc"
}

manage_tor_service() {
    info "Gerenciando serviço Tor..."
    pkill tor 2>/dev/null
    nohup tor -f "$TOR_DIR/torrc" > "$TOR_DIR/tor.log" 2>&1 &
    sleep 10
    grep -q "Bootstrapped 100%" "$TOR_DIR/tor.log" || {
        aviso "Tor falhou na inicialização. Tentando com bridges..."
        sed -i 's/UseBridges 0/UseBridges 1/' "$TOR_DIR/torrc"
        nohup tor -f "$TOR_DIR/torrc" > "$TOR_DIR/tor.log" 2>&1 &
        sleep 10
        grep -q "Bootstrapped 100%" "$TOR_DIR/tor.log" || erro "Falha ao conectar ao Tor. Verifique sua conexão ou tente outro bridge."
    }
    sucesso "Tor iniciado com sucesso!"
}

verify_connection() {
    info "Verificando conexão Tor..."
    torsocks curl -s --connect-timeout 20 https://check.torproject.org/api/ip | grep -q '"IsTor":true' && sucesso "Conexão Tor estabelecida!" || erro "Tor não está funcionando corretamente."
}

main() {
    clear
    info "=== INSTALADOR TOR PARA TERMUX ==="
    verify_environment
    install_packages
    configure_tor
    manage_tor_service
    verify_connection
    sucesso "Instalação concluída!"
}

main


