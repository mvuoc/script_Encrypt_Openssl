#!/bin/bash

R='\033[0;31m';G='\033[0;32m';Y='\033[1;33m';B='\033[0;34m';N='\033[0m'
A="aes-256-cbc"

banner() {
    clear
    printf "${B}╔════════════════════════════════════════════╗\n║   Script de Encriptación AES-256-CBC       ║\n║          OpenSSL + Base64                  ║\n╚════════════════════════════════════════════╝${N}\n\n"
}

pause() { printf "\n"; read -p "Presiona Enter para continuar..."; }

encrypt_data() { printf "%s" "$1" | openssl enc -$A -salt -pbkdf2 -pass pass:"$2" | base64 -w 0; }

decrypt_data() { printf "%s" "$1" | base64 -d | openssl enc -d -$A -pbkdf2 -pass pass:"$2" 2>/dev/null; }

export_content() {
    printf "\n"
    read -p "¿Exportar contenido? (s/n): " e
    [[ "$e" =~ ^[sS]$ ]] || return
    read -p "Archivo salida [$2]: " o
    printf "%s" "$1" > "${o:-$2}" && printf "${G}✓ Exportado: ${o:-$2}${N}\n" || printf "${R}✗ Error exportando${N}\n"
}

encrypt_file() {
    printf "${Y}=== ENCRIPTAR ARCHIVO ===${N}\n"
    read -p "Archivo: " f
    [[ -f "$f" ]] || { printf "${R}✗ Archivo no existe${N}\n"; pause; return; }
    read -sp "Contraseña: " p; printf "\n"
    read -sp "Confirmar: " p2; printf "\n"
    [[ "$p" == "$p2" ]] || { printf "${R}✗ Contraseñas no coinciden${N}\n"; pause; return; }
    o="${f}.enc"
    openssl enc -$A -salt -pbkdf2 -in "$f" -out "$o" -pass pass:"$p" && printf "${G}✓ Encriptado: $o${N}\n" || printf "${R}✗ Error${N}\n"
    pause
}

decrypt_file() {
    printf "${Y}=== DESENCRIPTAR ARCHIVO ===${N}\n"
    read -p "Archivo: " f
    [[ -f "$f" ]] || { printf "${R}✗ Archivo no existe${N}\n"; pause; return; }
    read -sp "Contraseña: " p; printf "\n"
    d=$(openssl enc -d -$A -pbkdf2 -in "$f" -pass pass:"$p" 2>/dev/null)
    if [[ $? -eq 0 && -n "$d" ]]; then
        printf "${G}✓ Desencriptado${N}\n\n${B}--- CONTENIDO ---${N}\n%s\n${B}--- FIN ---${N}\n" "$d"
        export_content "$d" "${f%.enc}.dec"
    else
        printf "${R}✗ Contraseña incorrecta${N}\n"
    fi
    pause
}

encrypt_text() {
    printf "${Y}=== ENCRIPTAR TEXTO ===${N}\nTexto (Ctrl+D termina):\n"
    t=$(cat)
    [[ -z "$t" ]] && { printf "${R}✗ Sin texto${N}\n"; pause; return; }
    read -sp "Contraseña: " p; printf "\n"
    read -sp "Confirmar: " p2; printf "\n"
    [[ "$p" == "$p2" ]] || { printf "${R}✗ Contraseñas no coinciden${N}\n"; pause; return; }
    e=$(encrypt_data "$t" "$p")
    [[ $? -eq 0 ]] && { printf "${G}✓ Encriptado${N}\n\n${B}--- TEXTO ---${N}\n%s\n${B}--- FIN ---${N}\n" "$e"; export_content "$e" "texto_encriptado.txt"; } || printf "${R}✗ Error${N}\n"
    pause
}

decrypt_text() {
    printf "${Y}=== DESENCRIPTAR TEXTO ===${N}\nTexto Base64 (Ctrl+D termina):\n"
    t=$(cat)
    [[ -z "$t" ]] && { printf "${R}✗ Sin texto${N}\n"; pause; return; }
    read -sp "Contraseña: " p; printf "\n"
    d=$(decrypt_data "$t" "$p")
    if [[ $? -eq 0 && -n "$d" ]]; then
        printf "${G}✓ Desencriptado${N}\n\n${B}--- TEXTO ---${N}\n%s\n${B}--- FIN ---${N}\n" "$d"
        export_content "$d" "texto_desencriptado.txt"
    else
        printf "${R}✗ Contraseña incorrecta${N}\n"
    fi
    pause
}

menu() {
    while :; do
        banner
        printf "${G}1.${N} Encriptar Archivo\n${G}2.${N} Desencriptar Archivo\n${G}3.${N} Encriptar Texto\n${G}4.${N} Desencriptar Texto\n${R}5.${N} Salir\n\n"
        read -p "Opción: " o
        case $o in
            1) encrypt_file ;;
            2) decrypt_file ;;
            3) encrypt_text ;;
            4) decrypt_text ;;
            5) printf "${B}¡Hasta luego!${N}\n"; exit 0 ;;
            *) printf "${R}✗ Opción inválida${N}\n"; pause ;;
        esac
    done
}

command -v openssl &>/dev/null || { printf "${R}✗ OpenSSL no instalado${N}\n"; exit 1; }

menu
