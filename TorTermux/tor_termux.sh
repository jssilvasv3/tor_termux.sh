#!/bin/bash

# Atualizando os repositórios do Termux
echo "[*] Atualizando repositórios..."
pkg update -y && pkg upgrade -y

# Instalando o Tor
echo "[*] Instalando Tor..."
pkg install tor -y

# Criando diretório de configuração se não existir
TOR_CONF_DIR="$HOME/.tor"
mkdir -p "$TOR_CONF_DIR"

# Criando arquivo de configuração padrão, se não existir
TORRC="$TOR_CONF_DIR/torrc"
if [ ! -f "$TORRC" ]; then
    echo "[*] Criando arquivo de configuração..."
    cat > "$TORRC" <<EOL
SocksPort 9050
ControlPort 9051
DataDirectory $TOR_CONF_DIR/data
EOL
fi

# Iniciando o Tor
echo "[*] Iniciando o serviço Tor..."
tor -f "$TORRC" &

# Aguardando o Tor inicializar
echo "[*] Aguardando inicialização do Tor..."
sleep 10

# Verificando se o Tor está rodando
if pgrep -x "tor" > /dev/null; then
    echo "[✔] Tor iniciado com sucesso!"
else
    echo "[✘] Falha ao iniciar o Tor. Verifique sua conexão ou tente novamente."
fi

