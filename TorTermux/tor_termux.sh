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

# Configuração simples para torrc (torrc básico para a execução padrão)
echo "
SocksPort 9050
ControlPort 9051
DataDirectory ~/.tor
" > ~/.tor/torrc

# Iniciar o Tor
echo "[*] Iniciando o Tor..."
tor &
echo "[*] Tor foi iniciado com sucesso!"

# Verificar o status do Tor
sleep 5
if ps aux | grep "[t]or" > /dev/null; then
    echo "[*] Tor está rodando corretamente!"
else
    echo "[!] Falha ao iniciar o Tor."
fi


# Finalizando
echo "[*] Processo concluído."


