#!/data/data/com.termux/files/usr/bin/bash

echo "[*] Atualizando pacotes..."
pkg update -y && pkg upgrade -y

echo "[*] Instalando dependências..."
pkg install tor -y

echo "[*] Criando diretório de configuração do Tor..."
mkdir -p $HOME/.tor

echo "[*] Gerando arquivo de configuração..."
cat > $HOME/.tor/torrc <<EOF
SocksPort 9050
ControlPort 9051
CookieAuthentication 1
EOF

echo "[*] Configuração concluída! Para iniciar o Tor, execute:"
echo "tor -f $HOME/.tor/torrc"


