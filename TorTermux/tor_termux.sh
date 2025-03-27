#!/data/data/com.termux/files/usr/bin/bash

echo "[*] Atualizando pacotes..."
yes | pkg update -y && yes | pkg upgrade -y

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

echo "[*] Instalação concluída!"
echo "[*] Digite 'tor' para iniciar."

# Esperar 2 segundos antes de iniciar o Tor automaticamente
sleep 2

echo "[*] Iniciando o Tor..."
tor -f $HOME/.tor/torrc | while read line; do
    echo "$line"
    if echo "$line" | grep -q "Bootstrapped 100%"; then
        echo "[*] Conexão Pronta!"
        echo "[*] Para encerrar, pressione Ctrl + C"
    fi
done


