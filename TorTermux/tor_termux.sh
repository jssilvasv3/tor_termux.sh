#!/data/data/com.termux/files/usr/bin/bash

# Atualiza pacotes
echo "[*] Atualizando pacotes..."
pkg update -y && pkg upgrade -y

# Verifica se o Tor já está instalado
if ! command -v tor >/dev/null 2>&1; then
    echo "[*] Instalando Tor..."
    pkg install tor -y
else
    echo "[*] Tor já está instalado!"
fi

# Configura o Tor
mkdir -p ~/.tor
cat > ~/.tor/torrc <<EOF
SocksPort 9050
ControlPort 9051
CookieAuthentication 1
Log notice stdout
EOF

# Inicia o Tor em segundo plano de forma segura
echo "[*] Iniciando o Tor..."
nohup tor -f ~/.tor/torrc > /dev/null 2>&1 &

# Mensagem de status
echo "[✔] Tor está rodando na porta 9050 (SOCKS5 Proxy)"
echo "[i] Para verificar o IP, use:"
echo 'curl --socks5 127.0.0.1:9050 https://check.torproject.org'
