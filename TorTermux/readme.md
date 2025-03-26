# 🧅 Tor para Termux

Este script instala e configura o **Tor** no Termux para atuar como um proxy SOCKS5 no Android.

## 📥 Instalação rápida

Execute este comando no Termux para baixar e instalar automaticamente:

```bash
Ctrl: curl -sL https://raw.githubusercontent.com/jssilvasv3/tor-termux/main/tor_termux.sh | bash



🚀 Recursos
✅ Instala automaticamente o Tor

✅ Configura o Tor com um proxy SOCKS5 na porta 9050

✅ Executa o Tor em segundo plano com nohup

✅ Permite verificar seu IP na rede Tor


#🛠 Como usar?
#Após a instalação, o Tor já estará rodando em segundo plano.
#Para testar se a conexão está passando pela rede Tor, use:

Ctrl: curl --socks5 127.0.0.1:9050 https://check.torproject.org

#Se estiver funcionando corretamente, a resposta indicará que você está conectado à rede Tor.


#🛑 Como parar o Tor?
#Caso precise parar o Tor, execute:

pkill tor


#📜 Licença
#Este projeto está sob a licença MIT. Sinta-se à vontade para modificar e compartilhar!


🔹 Criado por jssilvasv3 26/03/2025 🚀