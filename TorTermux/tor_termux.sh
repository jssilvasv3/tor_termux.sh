#!/data/data/com.termux/files/usr/bin/bash

echo "[*] Atualizando pacotes do Termux..."
pkg update -y
pkg upgrade -y

echo "[*] Instalando o Tor..."
pkg install -y tor

echo "[*] Instalando pacotes adicionais (dependências)..."
pkg install -y coreutils

# Criar a pasta de configuração do Tor, caso não exista
mkdir -p ~/.tor

# Criar arquivo de configuração torrc (ajustes simples)
echo "
SocksPort 127.0.0.1:9050
ControlPort 127.0.0.1:9051
DataDirectory /data/data/com.termux/files/home/.tor
Log notice file /data/data/com.termux/files/home/.tor/tor.log
" > ~/.tor/torrc

# Iniciar o Tor em segundo plano
echo "[*] Iniciando o Tor..."
tor --RunAsDaemon 1 &

# Verificando se o Tor foi iniciado corretamente
sleep 5
if ps aux | grep "[t]or" > /dev/null; then
    echo "[*] Tor está rodando corretamente!"
else
    echo "[!] Falha ao iniciar o Tor."
    cat ~/.tor/tor.log # Exibindo log de erros
fi



# Finalizando
echo "[*] Processo concluído."


