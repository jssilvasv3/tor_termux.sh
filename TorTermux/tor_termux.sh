#!/data/data/com.termux/files/usr/bin/bash

# ==============================================
# INSTALADOR TOR PARA TERMUX - VERSÃO DEFINITIVA
# ==============================================

# Cores melhoradas
RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[94m'
NC='\e[0m'

# Funções de mensagem
error() { echo -e "${RED}[✘]${NC} $1" >&2; exit 1; }
success() { echo -e "${GREEN}[✔]${NC} $1"; }
info() { echo -e "${BLUE}[*]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Verificação de ambiente
verify_env() {
    [ -d "$PREFIX" ] || error "Termux não detectado!"
    [ $(uname -o) = "Android" ] || warning "Recomendado executar no Android"
}

# Configuração especial para Android
android_config() {
    info "Aplicando otimizações para Android..."
    
    # Configurações de rede específicas
    cat > $HOME/.tor/torrc <<'EOF'
SocksPort 127.0.0.1:9050
ControlPort 9051
AvoidDiskWrites 1
ClientOnly 1
UseBridges 0
ConnectionPadding 1
CircuitBuildTimeout 120
KeepalivePeriod 30
NumEntryGuards 2
GeoIPExcludeUnknown 1
Log notice stdout
EOF

    # Configurações adicionais se necessário
    echo -e "\nVirtualAddrNetworkIPv4 10.192.0.0/10" >> $HOME/.tor/torrc
}

# Inicialização robusta do Tor
start_tor() {
    info "Iniciando Tor com configuração especial..."
    
    # Limpa processos anteriores
    pkill tor 2>/dev/null && sleep 2
    
    # Inicia em primeiro plano temporariamente
    tor -f $HOME/.tor/torrc > $HOME/.tor/tor.log 2>&1 &
    local tor_pid=$!
    
    # Espera adaptativa
    for i in {1..60}; do
        if grep -q "Bootstrapped 100%" $HOME/.tor/tor.log 2>/dev/null; then
            success "Tor iniciado com sucesso (PID: $tor_pid)"
            return 0
        fi
        sleep 1
    done
    
    error "Timeout na inicialização"
    warning "Últimas linhas do log:"
    tail -n 10 $HOME/.tor/tor.log >&2
    
    # Tentativa alternativa
    warning "Tentando método alternativo..."
    pkill tor
    tor --allow-missing-torrc > $HOME/.tor/tor.log 2>&1 &
    
    sleep 10
    if pgrep -x "tor" >/dev/null; then
        success "Tor iniciado (método alternativo)"
    else
        error "Falha persistente"
        echo "Relatório completo em: $HOME/.tor/tor.log"
        exit 1
    fi
}

# Fluxo principal
main() {
    clear
    echo -e "${BLUE}=== INSTALADOR TOR ULTRA-RESISTENTE ===${NC}"
    
    verify_env
    
    # Atualização segura
    info "Atualizando pacotes..."
    pkg update -y && pkg upgrade -y
    
    # Instalação essencial
    info "Instalando componentes..."
    pkg install -y tor torsocks curl
    
    # Configuração
    mkdir -p $HOME/.tor
    android_config
    
    # Inicialização
    start_tor
    
    # Verificação final
    info "Verificando conexão..."
    if torsocks curl -s https://check.torproject.org | grep -q "Congratulations"; then
        success "CONEXÃO TOR ESTABELECIDA!"
        echo -e "${GREEN}IP TOR:${NC} $(torsocks curl -s https://check.torproject.org/api/ip | grep -oP '(?<="Ip":")[^"]+')"
    else
        warning "Conexão não verificada automaticamente"
        echo "Execute manualmente para testar:"
        echo "torsocks curl https://check.torproject.org"
    fi
    
    echo -e "\n${GREEN}COMANDOS ÚTEIS:${NC}"
    echo "1. Ver logs: tail -f $HOME/.tor/tor.log"
    echo "2. Parar Tor: pkill tor"
    echo "3. Reiniciar: pkill tor && tor"
}

# Execução
main
