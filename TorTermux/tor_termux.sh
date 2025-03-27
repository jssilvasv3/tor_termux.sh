#!/data/data/com.termux/files/usr/bin/bash

# Atualizando repositórios
echo "[*] Atualizando repositórios..."
pkg update -y && pkg upgrade -y

# Instalando pacotes essenciais
echo "[*] Instalando pacotes essenciais..."
pkg install -y tor

# Aceitando alterações no bash.bashrc automaticamente (resposta padrão N)
echo "[*] Aceitando alterações no bash.bashrc..."
dpkg-reconfigure bash

# Iniciando o Tor
echo "[*] Iniciando Tor..."
tor &

# Verificando se o Tor foi iniciado corretamente
echo "[*] Verificando o status do Tor..."
if ps aux | grep '[t]or' > /dev/null
then
    echo "[*] Tor iniciado com sucesso!"
else
    echo "[!] Falha ao iniciar o Tor."
fi

# Finalizando
echo "[*] Processo concluído."


