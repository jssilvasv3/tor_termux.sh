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
    if ! pkg update -y >/dev/null 2>&1; then
        warning "Tentando com mirror alternativo..."
        sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirror.termux.com/termux stable main@' $PREFIX/etc/apt/sources.list
        pkg update -y || error "Falha crítica na atualização"
    fi

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
EOF

    # Configuração adicional para Android
    echo -e "\nVirtualAddrNetworkIPv4 10.192.0.0/10\nAutomapHostsOnResolve 1\nDNSPort 5353" >> "$TOR_DIR/torrc"
}

# Controle de serviço melhorado
manage_tor_service() {
    info "Gerenciando serviço Tor..."
    
    # Encerra processos existentes
    if pgrep -x "tor" >/dev/null; then
        warning "Tor já em execução - reiniciando..."
        pkill tor && sleep 2
    fi
    
    # Inicia com redirecionamento de logs
    nohup tor -f "$TOR_DIR/torrc" > "$TOR_DIR/tor.log" 2>&1 &
    
    # Espera inteligente com timeout
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
    
    local max_retries=3
    local retry_delay=5
    
    for ((i=1; i<=max_retries; i++)); do
        if torsocks curl -s --connect-timeout 20 https://check.torproject.org/api/ip | grep -q '"IsTor":true'; then
            local tor_ip=$(torsocks curl -s https://check.torproject.org/api/ip | grep -oP '(?<="Ip":")[^"]+')
            success "Conexão Tor estabelecida com sucesso!"
            success "IP Tor: $tor_ip"
            return 0
        fi
        
        if [ $i -lt $max_retries ]; then
            warning "Tentativa $i/$max_retries falhou - tentando novamente em $retry_delay segundos..."
            sleep $retry_delay
        fi
    done
    
    error "Falha ao verificar conexão Tor após $max_retries tentativas"
    warning "Sugestões para solução:"
    echo "1. Verifique sua conexão com a internet"
    echo "2. Tente usar bridges (edite ~/.tor/torrc e mude UseBridges para 1)"
    echo "3. Execute manualmente para ver logs detalhados:"
    echo "   tor -f ~/.tor/torrc"
    exit 1
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
if [ "$0" = "bash" ]; then
    warning "Execução via pipe detectada - instalando diretamente"
    main
else
    chmod +x "$0" 2>/dev/null
    main
fi
