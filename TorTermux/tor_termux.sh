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
read -p "[?] Deseja iniciar o Tor agora? (s/n): " resposta

if [[ "$resposta" =~ ^[sS]$ ]]; then
    echo "[*] Iniciando o Tor..."
    
    # Inicia o Tor em background e salva o PID
    tor -f $HOME/.tor/torrc > tor.log 2>&1 &  
    TOR_PID=$!

    echo "[*] Aguardando conexão..."
    
    # Monitorando o arquivo de log para verificar quando a conexão estiver pronta
    while ! grep -q "Bootstrapped 100%" tor.log; do
        sleep 2
    done

    echo "[*] Conexão Pronta!"
    echo "[*] Você pode iniciar o Tor depois digitando: tor"
    echo "[*] Para encerrar, pressione Ctrl + C"
    
    # Mantém o Tor rodando em primeiro plano
    wait $TOR_PID
else
    echo "[*] Você pode iniciar o Tor depois digitando: tor -f $HOME/.tor/torrc"
fi

