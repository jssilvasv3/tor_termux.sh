#!/data/data/com.termux/files/usr/bin/bash

# Cores
RED='\e[91m'
GREEN='\e[92m'
NC='\e[0m'

# Resolver conflitos de pacotes
fix_packages() {
    echo -e "${GREEN}[*]${NC} Resolvendo conflitos de pacotes..."
    pkg install -o Dpkg::Options::="--force-confold" -y bash --reinstall
    pkg install -y termux-tools
    dpkg --configure -a
}

# Instalação limpa do Tor
install_tor() {
    echo -e "${GREEN}[*]${NC} Instalando Tor..."
    pkg purge tor torsocks -y
    rm -rf ~/.tor
    pkg install -y tor torsocks
    
    mkdir -p ~/.tor
    cat > ~/.tor/torrc <<'EOF'
SocksPort 127.0.0.1:9050
ControlPort 9051
AvoidDiskWrites 1
ClientOnly 1
UseBridges 1
Bridge obfs4 193.11.166.194:27025 1F2F0FF7CDAE026A4E0F5E5C6D86910F3B2D5B7D
GeoIPExcludeUnknown 1
Log notice stdout
EOF
}

# Inicialização com verificação
start_tor() {
    echo -e "${GREEN}[*]${NC} Iniciando Tor..."
    pkill tor
    tor -f ~/.tor/torrc > ~/.tor/tor.log 2>&1 &
    
    for i in {1..30}; do
        if grep -q "Bootstrapped 100%" ~/.tor/tor.log 2>/dev/null; then
            echo -e "${GREEN}[✔]${NC} Tor iniciado com sucesso!"
            torsocks curl -s https://check.torproject.org | grep -q "Congratulations" && \
            echo -e "${GREEN}[✔]${NC} Conexão verificada!" || \
            echo -e "${RED}[!]${NC} Conexão ativa mas verificação falhou"
            return 0
        fi
        sleep 2
    done
    
    echo -e "${RED}[✘]${NC} Falha na inicialização"
    echo "Últimas linhas do log:"
    tail -n 10 ~/.tor/tor.log
    return 1
}

# Fluxo principal
fix_packages
install_tor
if start_tor; then
    echo -e "\n${GREEN}Instalação concluída com sucesso!${NC}"
    echo "Use: torsocks antes de comandos"
else
    echo -e "\n${RED}Problemas detectados.${NC} Tente:"
    echo "1. Mudar de rede (WiFi/dados)"
    echo "2. Usar outra bridge:"
    echo "   nano ~/.tor/torrc"
    echo "   Mude para: Bridge obfs4 154.35.22.11:443 FB70B257C162BF1038CA669D568D76F5B7F0BABB"
fi
    echo "3. Reiniciar: pkill tor && tor"
}

# Execução
main
