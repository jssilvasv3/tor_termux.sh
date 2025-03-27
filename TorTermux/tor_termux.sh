#!/data/data/com.termux/files/usr/bin/bash

# Atualizando pacotes
echo "[*] Atualizando repositórios..."
pkg update -y && pkg upgrade -y

# Instalando o Tor
echo "[*] Instalando o Tor..."
pkg install tor -y

# Criando diretório de configuração do Tor, se não existir
TOR_DIR="$HOME/.tor"
if [ ! -d "$TOR_DIR" ]; then
    mkdir -p "$TOR_DIR"
fi

# Criando um arquivo de configuração padrão, se não existir
TORRC_FILE="$TOR_DIR/torrc"
if [ ! -f "$TORRC_FILE" ]; then
    echo "SocksPort 9050" > "$TORRC_FILE"
    echo "ControlPort 9051" >> "$TORRC_FILE"
    echo "Log notice stdout" >> "$TORRC_FILE"
fi

# Iniciando o Tor
echo "[*] Iniciando o serviço Tor..."
tor -f "$TORRC_FILE" &

sleep 5

# Verificando se o Tor iniciou corretamente
if pgrep -x "tor" > /dev/null; then
    echo "[✔] Tor está rodando com sucesso!"
else
    echo "[✘] Falha ao iniciar o Tor. Verifique sua conexão ou tente novamente."
fi


