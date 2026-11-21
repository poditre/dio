#!/bin/bash
#
# 00-run-all.sh
#
# Script preguicoso pra rodar os 3 testes de uma vez so, sem precisar
# ficar chamando um por um. Util quando eu quero refazer tudo do zero
# pra tirar print de novo, por exemplo.
#
# Como usar: ./00-run-all.sh <IP_METASPLOITABLE> <IP_DVWA> <PHPSESSID_DVWA>

set -euo pipefail

IP_MSF="${1:-}"
IP_DVWA="${2:-}"
SESSID="${3:-}"

if [ -z "$IP_MSF" ] || [ -z "$IP_DVWA" ] || [ -z "$SESSID" ]; then
    echo "Uso: $0 <IP_METASPLOITABLE> <IP_DVWA> <PHPSESSID_DVWA>"
    exit 1
fi

echo "##################################################"
echo "# Teste 1/3 - Brute force no FTP"
echo "##################################################"
./01-ftp-bruteforce.sh "$IP_MSF"

echo
echo "##################################################"
echo "# Teste 2/3 - Tentativas no formulario do DVWA"
echo "##################################################"
./02-dvwa-webform.sh "$IP_DVWA" "$SESSID"

echo
echo "##################################################"
echo "# Teste 3/3 - Descobrir usuarios + Password Spraying no SMB"
echo "##################################################"
./03-smb-enum-spray.sh "$IP_MSF"

echo
echo "[*] Prontinho, rodou tudo! Da uma olhada na pasta ../resultados/"
