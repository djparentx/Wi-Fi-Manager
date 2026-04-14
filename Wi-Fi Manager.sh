#!/bin/bash

# =======================================
# Wi-Fi Manager 3.5.2 for ArkOS and dArkOS
# by djparent
# inspired by Wifi by Kris Henriksen
# =======================================

# Additional code adapted from Wifi-Toggle v3.6 and Bluetooth Manager for dArkOS by Jason3x

# Copyright (c) 2026 djparent
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

WIFI_LOG=OFF	# ON for logging
MONITOR=ON		# ON for connection healing

# -------------------------------------------------------
# Root privileges check
# -------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

# -------------------------------------------------------
# Creates a persistent NM config to disable wifi power saving
# Remove /etc/NetworkManager/conf.d/wifi-powersave-off.conf to revert
# -------------------------------------------------------
if [ ! -f /etc/NetworkManager/conf.d/wifi-powersave-off.conf ]; then
    cat > /etc/NetworkManager/conf.d/wifi-powersave-off.conf << 'EOF'
[connection]
wifi.powersave = 2
EOF
    nmcli general reload 2>/dev/null || true
fi

# -------------------------------------------------------
# Initialization
# -------------------------------------------------------
export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/
if [[ "$WIFI_LOG" == "ON" ]]; then
	export LOG_FILE="$(dirname "$(realpath "$0")")/wifi_monitor.log"
else
	export LOG_FILE="/dev/null"
fi

# -------------------------------------------------------
# Variables
# -------------------------------------------------------
old_ifs="$IFS"
SYSTEM_LANG=""
MONITOR_PID=""
GPTOKEYB_PID=""
CURR_TTY="/dev/tty1"
WIFI_USB_PATH="/sys/bus/usb/devices/1-1"
ES_CONF="/home/ark/.emulationstation/es_settings.cfg"
PREFERRED_WIFI_MODULES=("8188eu" "r8188eu" "rtl8723bu")

if [ -f "$ES_CONF" ]; then
    ES_DETECTED=$(grep "name=\"Language\"" "$ES_CONF" | grep -o 'value="[^"]*"' | cut -d '"' -f 2)
    [ -n "$ES_DETECTED" ] && SYSTEM_LANG="$ES_DETECTED"
fi

# -------------------------------------------------------
# Default configuration : EN
# -------------------------------------------------------
T_BACKTITLE="Wi-Fi Manager by djparent"
T_CONN_TO="Connected to"
T_BACKTITLE2="Wi-Fi Manager: $T_CONN_TO"
T_WAIT="Please wait ..."
T_STARTING="Starting Wi-Fi Manager ...\n$T_WAIT"
T_ON="ON"
T_OFF="OFF"
T_ERR_TITLE="Error"
T_DWC2_ERROR="Could not access unbind/bind interface for dwc2 driver."
T_USB_ERROR="USB controller ff300000.usb not found in /sys."
T_ENABLE_WIFI="Enabling Wi-Fi ..."
T_DISABLE_WIFI="Disabling Wi-Fi ..."
T_WIFI_ENABLED="Wi-Fi enabled."
T_PLEASE_WAIT="Please wait for connection."
T_WIFI_DISABLED="Wi-Fi disabled."
T_PLEASE_CHECK="Please check your network and try again."
T_CHECK_DEP="Check dependencies"
T_INTERNET="Internet Required"
T_ACTIVE="An active internet connection is required to install missing packages." 
T_PACKAGE="Installing missing packages:" 
T_COMPLETE="Installation successful:"
T_PKG_ERR="Could not install required packages"
T_TRY_AGAIN="Check your connection and try again."
T_REMOVE="Would you like to remove"
T_SAVED_TITLE="Saved Networks"
T_BACK="Back"
T_CONNECTING="Connecting to"
T_FAIL_CONNECT="Connecting failed. Please try again ..."
T_SUCCESS="Successfully connected to"
T_FAILED="Failed to connect to"
T_SCAN="Scanning available Networks ..."
T_AVAILABLE="Available Networks"
T_FORGET="Forget Network"
T_INFO="Network Information"
T_REMOTE="Remote Access"
T_START_REMOTE="Starting remote services ..."
T_STOP_REMOTE="Stopping remote services ..."
T_REMOTE_RUNNING="Remote services are running."
T_REMOTE_DISABLED="Remote services are disabled."
T_SHARING="sharing"
T_IP_ADDRESS="Your IP address is:"
T_PASSWORD="Enter Wi-Fi password for"
T_NONE="None"
T_STATUS="Status"
T_MAIN_TITLE="Main Menu"
T_ADD_NEW="Add New Network"
T_NO_SAVED="No saved networks."
T_ENABLE="Enable"
T_DISABLE="Disable"
T_EXIT="Exit"

# --- FRANCAIS (FR) ---
if [[ "$SYSTEM_LANG" == *"fr"* ]]; then
T_BACKTITLE="Wi-Fi Manager par djparent"
T_CONN_TO="Connecte a"
T_BACKTITLE2="Wi-Fi Manager: $T_CONN_TO"
T_WAIT="Veuillez patienter ..."
T_STARTING="Demarrage de Wi-Fi Manager ...\n$T_WAIT"
T_ON="ACTIVE"
T_OFF="DESACTIVE"
T_ERR_TITLE="Erreur"
T_DWC2_ERROR="Impossible d'acceder a l'interface unbind/bind du pilote dwc2."
T_USB_ERROR="Contrôleur USB ff300000.usb introuvable dans /sys."
T_ENABLE_WIFI="Activation du Wi-Fi ..."
T_DISABLE_WIFI="Desactivation du Wi-Fi ..."
T_WIFI_ENABLED="Wi-Fi active."
T_PLEASE_WAIT="Veuillez patienter pour la connexion."
T_WIFI_DISABLED="Wi-Fi desactive."
T_PLEASE_CHECK="Verifiez votre reseau et reessayez."
T_CHECK_DEP="Verification des dependances"
T_INTERNET="Connexion Internet requise"
T_ACTIVE="Une connexion Internet active est requise pour installer les paquets manquants."
T_PACKAGE="Installation des paquets manquants :"
T_COMPLETE="Installation reussie :"
T_PKG_ERR="Impossible d'installer les paquets requis"
T_TRY_AGAIN="Verifiez votre connexion et reessayez."
T_REMOVE="Voulez-vous supprimer"
T_SAVED_TITLE="Reseaux enregistres"
T_BACK="Retour"
T_CONNECTING="Connexion a"
T_FAIL_CONNECT="Echec de la connexion. Veuillez reessayer ..."
T_SUCCESS="Connecte avec succes a"
T_FAILED="Echec de la connexion a"
T_SCAN="Recherche des reseaux disponibles ..."
T_AVAILABLE="Reseaux disponibles"
T_FORGET="Oublier le reseau"
T_INFO="Informations reseau"
T_REMOTE="Acces a distance"
T_START_REMOTE="Demarrage des services distants ..."
T_STOP_REMOTE="Arret des services a distance ..."
T_REMOTE_RUNNING="Les services distants sont actifs."
T_REMOTE_DISABLED="Les services a distance sont desactives."
T_SHARING="partage"
T_IP_ADDRESS="Votre adresse IP est :"
T_PASSWORD="Entrez le mot de passe Wi-Fi pour"
T_NONE="Aucun"
T_STATUS="Statut"
T_MAIN_TITLE="Menu principal"
T_ADD_NEW="Ajouter un reseau"
T_NO_SAVED="Aucun reseau enregistre."
T_ENABLE="Activer"
T_DISABLE="Desactiver"
T_EXIT="Quitter"

# --- ESPANOL (ES) ---
elif [[ "$SYSTEM_LANG" == *"es"* ]]; then
T_BACKTITLE="Wi-Fi Manager por djparent"
T_CONN_TO="Conectado a"
T_BACKTITLE2="Wi-Fi Manager: $T_CONN_TO"
T_WAIT="Por favor espere ..."
T_STARTING="Iniciando Wi-Fi Manager ...\n$T_WAIT"
T_ON="ACTIVADO"
T_OFF="DESACTIVADO"
T_ERR_TITLE="Error"
T_DWC2_ERROR="No se pudo acceder a la interfaz unbind/bind del controlador dwc2."
T_USB_ERROR="Controlador USB ff300000.usb no encontrado en /sys."
T_ENABLE_WIFI="Activando Wi-Fi ..."
T_DISABLE_WIFI="Desactivando Wi-Fi ..."
T_WIFI_ENABLED="Wi-Fi activado."
T_PLEASE_WAIT="Por favor espere la conexion."
T_WIFI_DISABLED="Wi-Fi desactivado."
T_PLEASE_CHECK="Compruebe su red e intentelo de nuevo."
T_CHECK_DEP="Comprobando dependencias"
T_INTERNET="Conexion a Internet requerida"
T_ACTIVE="Se requiere una conexion a Internet activa para instalar los paquetes faltantes."
T_PACKAGE="Instalando paquetes faltantes:"
T_COMPLETE="Instalacion exitosa:"
T_PKG_ERR="No se pudieron instalar los paquetes requeridos"
T_TRY_AGAIN="Verifica tu conexion y vuelve a intentarlo."
T_REMOVE="¿Desea eliminar"
T_SAVED_TITLE="Redes guardadas"
T_BACK="Volver"
T_CONNECTING="Conectando a"
T_FAIL_CONNECT="Error de conexion. Por favor intentelo de nuevo ..."
T_SUCCESS="Conectado exitosamente a"
T_FAILED="Error al conectar a"
T_SCAN="Buscando redes disponibles ..."
T_AVAILABLE="Redes disponibles"
T_FORGET="Olvidar red"
T_INFO="Informacion de red"
T_REMOTE="Acceso remoto"
T_START_REMOTE="Iniciando servicios remotos ..."
T_STOP_REMOTE="Deteniendo los servicios remotos ..."
T_REMOTE_RUNNING="Los servicios remotos estan activos."
T_REMOTE_DISABLED="Los servicios remotos estan desactivados."
T_SHARING="compartiendo"
T_IP_ADDRESS="Su direccion IP es:"
T_PASSWORD="Introduzca la contraseña Wi-Fi para"
T_NONE="Ninguno"
T_STATUS="Estado"
T_MAIN_TITLE="Menu principal"
T_ADD_NEW="Agregar nueva red"
T_NO_SAVED="No hay redes guardadas."
T_ENABLE="Activar"
T_DISABLE="Desactivar"
T_EXIT="Salir"

# --- PORTUGUES (PT) ---
elif [[ "$SYSTEM_LANG" == *"pt"* ]]; then
T_BACKTITLE="Wi-Fi Manager por djparent"
T_CONN_TO="Conectado a"
T_BACKTITLE2="Wi-Fi Manager: $T_CONN_TO"
T_WAIT="Por favor aguarde ..."
T_STARTING="Iniciando Wi-Fi Manager ...\n$T_WAIT"
T_ON="ATIVADO"
T_OFF="DESATIVADO"
T_ERR_TITLE="Erro"
T_DWC2_ERROR="Nao foi possível aceder a interface unbind/bind do controlador dwc2."
T_USB_ERROR="Controlador USB ff300000.usb nao encontrado em /sys."
T_ENABLE_WIFI="Ativando Wi-Fi ..."
T_DISABLE_WIFI="Desativando Wi-Fi ..."
T_WIFI_ENABLED="Wi-Fi ativado."
T_PLEASE_WAIT="Por favor aguarde a conexao."
T_WIFI_DISABLED="Wi-Fi desativado."
T_PLEASE_CHECK="Verifique a sua rede e tente novamente."
T_CHECK_DEP="Verificando dependencias"
T_INTERNET="Conexao a Internet necessaria"
T_ACTIVE="E necessaria uma conexao ativa a Internet para instalar os pacotes em falta."
T_PACKAGE="Instalando pacotes em falta:"
T_COMPLETE="Instalacao concluída com exito:"
T_PKG_ERR="Nao foi possível instalar os pacotes necessarios"
T_TRY_AGAIN="Verifique sua conexao e tente novamente."
T_REMOVE="Deseja remover"
T_SAVED_TITLE="Redes guardadas"
T_BACK="Voltar"
T_CONNECTING="Conectando a"
T_FAIL_CONNECT="Falha na conexao. Por favor tente novamente ..."
T_SUCCESS="Conectado com exito a"
T_FAILED="Falha ao conectar a"
T_SCAN="Procurando redes disponíveis ..."
T_AVAILABLE="Redes disponíveis"
T_FORGET="Esquecer rede"
T_INFO="Informacoes de rede"
T_REMOTE="Accesso remoto"
T_START_REMOTE="Iniciando servicos remotos ..."
T_STOP_REMOTE="Parando os servicos remotos ..."
T_REMOTE_RUNNING="Os servicos remotos estao ativos."
T_REMOTE_DISABLED="Os servicos remotos estao desativados."
T_SHARING="compartilhando"
T_IP_ADDRESS="O seu endereco IP e:"
T_PASSWORD="Introduza a senha Wi-Fi para"
T_NONE="Nenhum"
T_STATUS="Estado"
T_MAIN_TITLE="Menu principal"
T_ADD_NEW="Adicionar nova rede"
T_NO_SAVED="Nenhuma rede guardada."
T_ENABLE="Ativar"
T_DISABLE="Desativar"
T_EXIT="Sair"

# --- ITALIANO (IT) ---
elif [[ "$SYSTEM_LANG" == *"it"* ]]; then
T_BACKTITLE="Wi-Fi Manager di djparent"
T_CONN_TO="Connesso a"
T_BACKTITLE2="Wi-Fi Manager: $T_CONN_TO"
T_WAIT="Attendere prego ..."
T_STARTING="Avvio di Wi-Fi Manager ...\n$T_WAIT"
T_ON="ATTIVO"
T_OFF="DISATTIVO"
T_ERR_TITLE="Errore"
T_DWC2_ERROR="Impossibile accedere all'interfaccia unbind/bind del driver dwc2."
T_USB_ERROR="Controller USB ff300000.usb non trovato in /sys."
T_ENABLE_WIFI="Attivazione Wi-Fi ..."
T_DISABLE_WIFI="Disattivazione Wi-Fi ..."
T_WIFI_ENABLED="Wi-Fi attivato."
T_PLEASE_WAIT="Attendere per la connessione."
T_WIFI_DISABLED="Wi-Fi disattivato."
T_PLEASE_CHECK="Controlla la tua rete e riprova."
T_CHECK_DEP="Verifica delle dipendenze"
T_INTERNET="Connessione Internet richiesta"
T_ACTIVE="È necessaria una connessione Internet attiva per installare i pacchetti mancanti."
T_PACKAGE="Installazione pacchetti mancanti:"
T_COMPLETE="Installazione completata:"
T_PKG_ERR="Impossibile installare i pacchetti richiesti"
T_TRY_AGAIN="Controlla la tua connessione e riprova."
T_REMOVE="Vuoi rimuovere"
T_SAVED_TITLE="Reti salvate"
T_BACK="Indietro"
T_CONNECTING="Connessione a"
T_FAIL_CONNECT="Connessione fallita. Riprova ..."
T_SUCCESS="Connesso con successo a"
T_FAILED="Impossibile connettersi a"
T_SCAN="Ricerca reti disponibili ..."
T_AVAILABLE="Reti disponibili"
T_FORGET="Dimentica rete"
T_INFO="Informazioni di rete"
T_REMOTE="Accesso remoto"
T_START_REMOTE="Avvio dei servizi remoti ..."
T_STOP_REMOTE="Arresto dei servizi remoti ..."
T_REMOTE_RUNNING="I servizi remoti sono attivi."
T_REMOTE_DISABLED="I servizi remoti sono disabilitati."
T_SHARING="condivisione"
T_IP_ADDRESS="Il tuo indirizzo IP e:"
T_PASSWORD="Inserisci la password Wi-Fi per"
T_NONE="Nessuno"
T_STATUS="Stato"
T_MAIN_TITLE="Menu principale"
T_ADD_NEW="Aggiungi nuova rete"
T_NO_SAVED="Nessuna rete salvata."
T_ENABLE="Attiva"
T_DISABLE="Disattiva"
T_EXIT="Esci"

# --- DEUTSCH (DE) ---
elif [[ "$SYSTEM_LANG" == *"de"* ]]; then
T_BACKTITLE="Wi-Fi Manager von djparent"
T_CONN_TO="Verbunden mit"
T_BACKTITLE2="Wi-Fi Manager: $T_CONN_TO"
T_WAIT="Bitte warten ..."
T_STARTING="Wi-Fi Manager wird gestartet ...\n$T_WAIT"
T_ON="AKTIV"
T_OFF="INAKTIV"
T_ERR_TITLE="Fehler"
T_DWC2_ERROR="Zugriff auf die unbind/bind-Schnittstelle des dwc2-Treibers nicht moeglich."
T_USB_ERROR="USB-Controller ff300000.usb nicht in /sys gefunden."
T_ENABLE_WIFI="Wi-Fi wird aktiviert ..."
T_DISABLE_WIFI="Wi-Fi wird deaktiviert ..."
T_WIFI_ENABLED="Wi-Fi aktiviert."
T_PLEASE_WAIT="Bitte auf Verbindung warten."
T_WIFI_DISABLED="Wi-Fi deaktiviert."
T_PLEASE_CHECK="Bitte ueberpruefen Sie Ihr Netzwerk und versuchen Sie es erneut."
T_CHECK_DEP="Abhaengigkeiten pruefen"
T_INTERNET="Internetverbindung erforderlich"
T_ACTIVE="Eine aktive Internetverbindung ist erforderlich, um fehlende Pakete zu installieren."
T_PACKAGE="Fehlende Pakete werden installiert:"
T_COMPLETE="Installation erfolgreich:"
T_PKG_ERR="Erforderliche Pakete konnten nicht installiert werden"
T_TRY_AGAIN="Ueberpruefen Sie Ihre Verbindung und versuchen Sie es erneut."
T_REMOVE="Moechten Sie entfernen"
T_SAVED_TITLE="Gespeicherte Netzwerke"
T_BACK="Zurueck"
T_CONNECTING="Verbindung zu"
T_FAIL_CONNECT="Verbindung fehlgeschlagen. Bitte erneut versuchen ..."
T_SUCCESS="Erfolgreich verbunden mit"
T_FAILED="Verbindung fehlgeschlagen zu"
T_SCAN="Verfuegbare Netzwerke werden gesucht ..."
T_AVAILABLE="Verfuegbare Netzwerke"
T_FORGET="Netzwerk vergessen"
T_INFO="Netzwerkinformationen"
T_REMOTE="Fernzugriff"
T_START_REMOTE="Remote-Dienste werden gestartet ..."
T_STOP_REMOTE="Remote-Dienste werden gestoppt ..."
T_REMOTE_RUNNING="Remote-Dienste sind aktiv."
T_REMOTE_DISABLED="Remote-Dienste sind deaktiviert."
T_SHARING="freigeben"
T_IP_ADDRESS="Ihre IP-Adresse ist:"
T_PASSWORD="Wi-Fi-Passwort eingeben fuer"
T_NONE="Keine"
T_STATUS="Status"
T_MAIN_TITLE="Hauptmenue"
T_ADD_NEW="Neues Netzwerk hinzufuegen"
T_NO_SAVED="Keine gespeicherten Netzwerke."
T_ENABLE="Aktivieren"
T_DISABLE="Deaktivieren"
T_EXIT="Beenden"

# --- POLSKI (PL) ---
elif [[ "$SYSTEM_LANG" == *"pl"* ]]; then
T_BACKTITLE="Wi-Fi Manager przez djparent"
T_CONN_TO="Polaczono z"
T_BACKTITLE2="Wi-Fi Manager: $T_CONN_TO"
T_WAIT="Prosze czekac ..."
T_STARTING="Uruchamianie Wi-Fi Manager ...\n$T_WAIT"
T_ON="WLACZONY"
T_OFF="WYLACZONY"
T_ERR_TITLE="Blad"
T_DWC2_ERROR="Nie mozna uzyskac dostepu do interfejsu unbind/bind sterownika dwc2."
T_USB_ERROR="Kontroler USB ff300000.usb nie zostal znaleziony w /sys."
T_ENABLE_WIFI="Wlaczanie Wi-Fi ..."
T_DISABLE_WIFI="Wylaczanie Wi-Fi ..."
T_WIFI_ENABLED="Wi-Fi wlaczone."
T_PLEASE_WAIT="Prosze czekac na polaczenie."
T_WIFI_DISABLED="Wi-Fi wylaczone."
T_PLEASE_CHECK="Sprawdz siec i sprobuj ponownie."
T_CHECK_DEP="Sprawdzanie zaleznosci"
T_INTERNET="Wymagane polaczenie z internetem"
T_ACTIVE="Aktywne polaczenie z internetem jest wymagane do zainstalowania brakujacych pakietow."
T_PACKAGE="Instalowanie brakujacych pakietow:"
T_COMPLETE="Instalacja zakonczona pomyslnie:"
T_PKG_ERR="Nie mozna zainstalowac wymaganych pakietow"
T_TRY_AGAIN="Sprawdz swoje polaczenie i sprobuj ponownie."
T_REMOVE="Czy chcesz usunac"
T_SAVED_TITLE="Zapisane sieci"
T_BACK="Wstecz"
T_CONNECTING="Laczenie z"
T_FAIL_CONNECT="Polaczenie nieudane. Sprobuj ponownie ..."
T_SUCCESS="Pomyslnie polaczono z"
T_FAILED="Nie udalo sie polaczyc z"
T_SCAN="Wyszukiwanie dostepnych sieci ..."
T_AVAILABLE="Dostepne sieci"
T_FORGET="Zapomnij siec"
T_INFO="Informacje o sieci"
T_REMOTE="Dostep zdalny"
T_START_REMOTE="Uruchamianie uslug zdalnych ..."
T_STOP_REMOTE="Zatrzymywanie uslug zdalnych ..."
T_REMOTE_RUNNING="Uslugi zdalne sa aktywne."
T_REMOTE_DISABLED="Uslugi zdalne sa wylaczone."
T_SHARING="udostepnianie"
T_IP_ADDRESS="Twoj adres IP to:"
T_PASSWORD="Wprowadz haslo Wi-Fi dla"
T_NONE="Brak"
T_STATUS="Status"
T_MAIN_TITLE="Menu glowne"
T_ADD_NEW="Dodaj nowa siec"
T_NO_SAVED="Brak zapisanych sieci."
T_ENABLE="Wlacz"
T_DISABLE="Wylacz"
T_EXIT="Wyjscie"
fi

# -------------------------------------------------------
# Start gamepad input
# -------------------------------------------------------
Start_GPTKeyb() {
    pkill -9 -f gptokeyb 2>/dev/null || true
    if [ -n "$GPTOKEYB_PID" ]; then
        kill "$GPTOKEYB_PID" 2>/dev/null
    fi
    sleep 0.1
    /opt/inttools/gptokeyb -1 "$0" -c "/opt/inttools/keys.gptk" > /dev/null 2>&1 &
    GPTOKEYB_PID=$!
}

# -------------------------------------------------------
# Stop gamepad input
# -------------------------------------------------------
Stop_GPTKeyb() {
    if [ -n "$GPTOKEYB_PID" ]; then
        kill "$GPTOKEYB_PID" 2>/dev/null
        GPTOKEYB_PID=""
    fi
}

# -------------------------------------------------------
# Font Selection
# -------------------------------------------------------
ORIGINAL_FONT=$(setfont -v 2>&1 | grep -o '/.*\.psf.*')
setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz

# -------------------------------------------------------
# Display Management
# -------------------------------------------------------
printf "\e[?25l" > "$CURR_TTY"
dialog --clear
Stop_GPTKeyb
pgrep -f osk.py | xargs kill -9
printf "\033[H\033[2J" > "$CURR_TTY"
printf "$T_STARTING" > "$CURR_TTY"
sleep 0.5

# -------------------------------------------------------
# Wifi status
# -------------------------------------------------------
Get_Wifi_Status() {
    if command -v rfkill &> /dev/null; then
        if rfkill list wifi | grep -q "Soft blocked: yes"; then
            echo "OFF"
            return
        fi
        local iface
        iface=$(ip link show | awk '/wlan[0-9]+:/ {gsub(":", ""); print $2; exit}' || true)
        if [[ -n "$iface" ]] && ip link show "$iface" | grep -q "<.*UP.*>"; then
            echo "ON"
            return
        fi
    fi
    echo "OFF"
}

# -------------------------------------------------------
# Get current Wifi interface
# -------------------------------------------------------
Get_Wifi_Interface() {
    ip link show | awk '/wlan[0-9]+:/ {gsub(":", ""); print $2; exit}'
}

# -------------------------------------------------------
# Get current network
# -------------------------------------------------------
Get_Current_AP() {
	iface=$(Get_Wifi_Interface)
	cur_ap=$(iw dev "$iface" info | grep ssid | cut -c 7-30)
	if [[ -z $cur_ap ]]; then
        cur_ap=`nmcli -t -f name,device connection show --active | grep "$iface" | cut -d\: -f1`
	fi
	if [[ -z $cur_ap ]]; then
        cur_ap="$T_NONE"
    fi
}

# -------------------------------------------------------
# Detect installed Wifi modules
# -------------------------------------------------------
Detect_Wifi_Modules() {
    local modules_found_raw=()
    local module_name
    local modinfo_output

    local iface module_path
    for iface in $(ls /sys/class/net 2>/dev/null | grep '^wlan' || true); do
        if [[ -L "/sys/class/net/$iface/device/driver/module" ]]; then
            module_path=$(readlink -f "/sys/class/net/$iface/device/driver/module" 2>/dev/null)
            if [[ -n "$module_path" && -e "$module_path" ]]; then
                module_name=$(basename "$module_path")
                [[ -n "$module_name" && ! " ${modules_found_raw[*]} " =~ " $module_name " ]] && modules_found_raw+=("$module_name")
            fi
        fi
    done

    if command -v lsmod &>/dev/null && command -v modinfo &>/dev/null; then
        while IFS= read -r line; do
            current_mod_name=$(echo "$line" | awk '{print $1}')
            if [[ "$current_mod_name" != "Module" && -n "$current_mod_name" ]]; then
                modinfo_output=$(modinfo "$current_mod_name" 2>/dev/null || continue)
                if echo "$modinfo_output" | grep -qE \
                    -e 'filename:\s*.*drivers/net/wireless/' \
                    -e 'filename:\s*.*net/wireless/' \
                    -e 'depends:\s*([^,]*,)?(cfg80211|mac80211)(,|$)'
                then
                    [[ ! " ${modules_found_raw[*]} " =~ " $current_mod_name " ]] && modules_found_raw+=("$current_mod_name")
                fi
            fi
        done < <(lsmod 2>/dev/null || true)
    fi

    local helpers_to_exclude=("cfg80211" "mac80211" "rfkill" "lib80211" "libarc4")
    local final_modules=()
    local mod_to_check
    local is_helper

    for mod_to_check in "${modules_found_raw[@]}"; do
        is_helper=false
        for helper in "${helpers_to_exclude[@]}"; do
            if [[ "$mod_to_check" == "$helper" ]]; then
                is_helper=true
                break
            fi
        done
        if ! $is_helper; then
            if [[ ! " ${final_modules[*]} " =~ " $mod_to_check " ]]; then
                final_modules+=("$mod_to_check")
            fi
        fi
    done

    echo "${final_modules[@]}"
}

# -------------------------------------------------------
# Detect and add new WiFi modules to the preferred list
# -------------------------------------------------------
Update_Preferred_Modules() {
    detected_modules_array=($(Detect_Wifi_Modules))
    DETECTED_WIFI_MODULES=("${detected_modules_array[@]}")
    if [ ${#detected_modules_array[@]} -gt 0 ]; then
        declare -A unique_modules
        for module in "${PREFERRED_WIFI_MODULES[@]}" "${detected_modules_array[@]}"; do
            [[ -n "$module" ]] && unique_modules["$module"]=1
        done
        PREFERRED_WIFI_MODULES=("${!unique_modules[@]}")
    fi
}

# -------------------------------------------------------
# Enable Wifi Core
# -------------------------------------------------------
Enable_Wifi_Core() {
    local module_loaded_successfully=false
    local disabled_list_file="/etc/wifi_disabled_modules.list"

    for mod_to_unblacklist in "${PREFERRED_WIFI_MODULES[@]}"; do
        sed -i "/^\s*blacklist\s\+$mod_to_unblacklist\b/d" /etc/modprobe.d/*.conf 2>/dev/null || true
    done
    
    rfkill unblock wifi 2>/dev/null || true

    if [ -f "$disabled_list_file" ]; then
        while read -r mod; do
            [[ -n "$mod" ]] && modprobe "$mod" 2>/dev/null || true
        done < "$disabled_list_file"
        rm -f "$disabled_list_file"
    fi

    for preferred_mod in "${PREFERRED_WIFI_MODULES[@]}"; do
        if modprobe "$preferred_mod" 2>/dev/null; then
            module_loaded_successfully=true
        fi
    done

    if $module_loaded_successfully; then
        systemctl restart wpa_supplicant >/dev/null 2>&1 || systemctl start wpa_supplicant >/dev/null 2>&1
        local iface_check
        iface_check=$(ip link show | awk '/wlan[0-9]+:/ {gsub(":", ""); print $2; exit}' || true)
        if [[ -n "$iface_check" ]]; then
            ip link set "$iface_check" down 2>/dev/null || true
            ip link set "$iface_check" up 2>/dev/null || true
        fi
        if command -v nmcli &>/dev/null; then
            nmcli radio wifi on 2>/dev/null || true
        fi
    fi
}

# -------------------------------------------------------
# Eject WiFi adapter from USB bus
# -------------------------------------------------------
Eject_Wifi() {
	if [[ -d "$WIFI_USB_PATH" && -w "$WIFI_USB_PATH/remove" ]]; then
        echo 1 > "$WIFI_USB_PATH/remove" 2>/dev/null || true
    fi
}

# -------------------------------------------------------
# Unload WiFi kernel modules
# -------------------------------------------------------
Eject_Module() {
    local disabled_list_file="/etc/wifi_disabled_modules.list"
    : > "$disabled_list_file"

    local modules_to_process_for_disable=("${DETECTED_WIFI_MODULES[@]}" "${PREFERRED_WIFI_MODULES[@]}")
    local unique_modules_to_disable=($(echo "${modules_to_process_for_disable[@]}" | tr ' ' '\n' | awk 'NF' | sort -u | tr '\n' ' '))

    if [[ ${#unique_modules_to_disable[@]} -gt 0 ]]; then
        
        for mod in "${unique_modules_to_disable[@]}"; do
            [[ -z "$mod" ]] && continue
            
            sed -i "/^\s*blacklist\s\+$mod\b/d" /etc/modprobe.d/*.conf 2>/dev/null || true
        done

        for mod in "${unique_modules_to_disable[@]}"; do
            [[ -z "$mod" ]] && continue
            echo "$mod" >> "$disabled_list_file"
            modprobe -r -q "$mod" 2>/dev/null || true
        done

    fi
}

# -------------------------------------------------------
# Reconfigure USB port for OTG/WiFi switching
# -------------------------------------------------------
OTG() {
	if [[ -w /sys/module/usbcore/parameters/old_scheme_first ]]; then
        echo "1" > /sys/module/usbcore/parameters/old_scheme_first || true
    fi

    SERVICE_FILE="/etc/systemd/system/wifi-usb-old-scheme.service"

	if [[ ! -f "$SERVICE_FILE" ]]; then
        cat <<'EOF' > "$SERVICE_FILE"
[Unit]
Description=Enable old USB enumeration scheme for OTG compatibility and restart dwc2
After=multi-user.target
DefaultDependencies=no
[Service]
Type=oneshot
ExecStart=/bin/bash -c '
echo "1" > /sys/module/usbcore/parameters/old_scheme_first || true
if grep -q "^dwc2 " /proc/modules; then
    modprobe -r dwc2 || true
    sleep 0.5
    modprobe dwc2 || true
else
    if [[ -e /sys/bus/platform/devices/ff300000.usb ]]; then
        if [[ -e /sys/bus/platform/drivers/dwc2/unbind ]]; then
            echo ff300000.usb > /sys/bus/platform/drivers/dwc2/unbind || true
            sleep 0.5
            echo ff300000.usb > /sys/bus/platform/drivers/dwc2/bind || true
        fi
    fi
fi
'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

        chmod 644 "$SERVICE_FILE"
        systemctl daemon-reload
        systemctl enable wifi-usb-old-scheme.service >/dev/null 2>&1
	fi
    
    if grep -q "^dwc2 " /proc/modules; then
        modprobe -r dwc2 || true
		sleep 1
        modprobe dwc2 || true
    else
        if [[ -e /sys/bus/platform/devices/ff300000.usb ]]; then
            if [[ -e /sys/bus/platform/drivers/dwc2/unbind ]]; then
                echo ff300000.usb > /sys/bus/platform/drivers/dwc2/unbind || true
                echo ff300000.usb > /sys/bus/platform/drivers/dwc2/bind || true
            else
                dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_ERR_TITLE" --msgbox "\n$T_DWC2_ERROR" 6 60 > "$CURR_TTY"
            fi
        else
            dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_ERR_TITLE" --msgbox "\n$T_USB_ERROR" 6 60 > "$CURR_TTY"
        fi
    fi
    udevadm settle && sleep 1
}    

# -------------------------------------------------------
# Background connection monitor
# -------------------------------------------------------
Start_Connection_Monitor() {
    if [ -f /tmp/wifi_monitor.pid ]; then
        old_pid=$(cat /tmp/wifi_monitor.pid)
        pkill -P "$old_pid" 2>/dev/null || true
        kill "$old_pid" 2>/dev/null || true
        rm -f /tmp/wifi_monitor.pid
    fi
    [ -n "$MONITOR_PID" ] && { kill "$MONITOR_PID" 2>/dev/null || true; }

    (
        consecutive_failures=0
        sleep 15
        while true; do
            sleep 5
            
            [ -f /tmp/wifi_manager_state ] || continue
            [ "$(cat /tmp/wifi_manager_state)" = "ON" ] || continue
            
            iface=$(ip link show | awk '/wlan[0-9]+:/ {gsub(":", ""); print $2; exit}' || true)
            [ -z "$iface" ] && continue
            
            state=$(nmcli -t -f DEVICE,STATE dev 2>/dev/null | awk -F: -v i="$iface" '$1==i {print $2}')
            ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2; exit}')
            
            if [ "$state" = "connected" ] && [ -n "$ip" ]; then
                consecutive_failures=0
                continue
            fi
            
            consecutive_failures=$((consecutive_failures + 1))
            [ $consecutive_failures -lt 3 ] && continue
            consecutive_failures=0
            
            echo "[$(date '+%H:%M:%S')] Disconnection detected on $iface" >> "$LOG_FILE"
            ip addr flush dev "$iface" >/dev/null 2>&1 || true
            
            elapsed=0
            while [ $elapsed -lt 30 ]; do
                last_ssid=$(nmcli -t -f NAME,DEVICE con show --active 2>/dev/null | grep "$iface" | cut -d: -f1)
                [ -z "$last_ssid" ] && last_ssid=$(nmcli -t -f NAME con show 2>/dev/null | head -1)
                if nmcli con up "$last_ssid" >/dev/null 2>&1; then
                    sleep 3
                    new_ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2; exit}')
                    if [ -n "$new_ip" ]; then
                        echo "[$(date '+%H:%M:%S')] Reconnected successfully after ${elapsed}s" >> "$LOG_FILE"
                        break
                    fi
                fi
                sleep 5
                elapsed=$((elapsed + 5))
            done
            if [ $elapsed -ge 30 ]; then
                echo "[$(date '+%H:%M:%S')] Reconnect failed after 30s" >> "$LOG_FILE"
            fi
        done
    ) &
    MONITOR_PID=$!
    echo "$MONITOR_PID" > /tmp/wifi_monitor.pid
}

# -------------------------------------------------------
# Stop connection monitor
# -------------------------------------------------------
Stop_Connection_Monitor() {
    if [ -f /tmp/wifi_monitor.pid ]; then
        old_pid=$(cat /tmp/wifi_monitor.pid)
        pkill -P "$old_pid" 2>/dev/null || true
        kill "$old_pid" 2>/dev/null || true
        rm -f /tmp/wifi_monitor.pid
    fi
    if [ -n "$MONITOR_PID" ]; then
        pkill -P "$MONITOR_PID" 2>/dev/null || true
        { kill "$MONITOR_PID" 2>/dev/null || true; }
    fi
    MONITOR_PID=""
}

# -------------------------------------------------------
# Turn on Wifi
# -------------------------------------------------------
Enable_Wifi() {
    dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_STATUS" --infobox "\n  $T_ENABLE_WIFI" 5 40 > "$CURR_TTY"
    OTG
    Enable_Wifi_Core
	
    # --- Wait up to 12 seconds for interface to come up ---
    local timeout=12
    local iface_check=""
    while [[ $timeout -gt 0 ]]; do
        iface_check=$(ip link show | awk '/wlan[0-9]+:/ {gsub(":", ""); print $2; exit}' || true)
        if [[ -n "$iface_check" ]]; then
            iwconfig "$iface_check" power off 2>/dev/null || true
			break
        fi
        sleep 1
        (( timeout-- ))
    done

    dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_STATUS" --infobox "\n  $T_WIFI_ENABLED\n\n  $T_PLEASE_WAIT" 7 40 > "$CURR_TTY"

    echo "ON" > /tmp/wifi_manager_state
	
	# --- Remove sleep hook so wifi stays on across suspend/resume ---
	rm -f /etc/systemd/system-sleep/wifi-manager-hook.sh
		
    systemctl start wifi-usb-old-scheme.service
	
	for ((i=0; i<12; i++)); do
		iface_check=$(ip link show | awk '/wlan[0-9]+:/ {gsub(":", ""); print $2; exit}' || true)
		if [ -z "$iface_check" ]; then
			sleep 0.5
			continue
		fi

		state=$(nmcli -t -f DEVICE,STATE dev | awk -F: -v i="$iface_check" '$1==i {print $2}')
		
		if [ "$state" = "connected" ]; then
			break
		fi
		sleep 0.5
	done
	[[ "$MONITOR" == "ON" ]] && Start_Connection_Monitor

}

# -------------------------------------------------------
# Turn off Wifi
# -------------------------------------------------------
Disable_Wifi() {
	dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_STATUS" --infobox "\n  $T_DISABLE_WIFI" 5 40 > "$CURR_TTY"
    [[ "$MONITOR" == "ON" ]] && Stop_Connection_Monitor
	rfkill block wifi
    if command -v nmcli &>/dev/null; then
        nmcli radio wifi off
    fi
    systemctl stop wpa_supplicant 2>/dev/null || true
    
	Eject_Module
    Eject_Wifi
    OTG 2>/dev/null || true
    
    echo "OFF" > /tmp/wifi_manager_state
		cur_ap="$T_NONE"
	
	# --- create sleep hook to keep wifi off across suspend/resume ---
	cat > /etc/systemd/system-sleep/wifi-manager-hook.sh << EOF
#!/bin/bash
if [ "\$1" = "post" ]; then
    sleep 2
    if [ -f /tmp/wifi_manager_state ] && [ "\$(cat /tmp/wifi_manager_state)" = "OFF" ]; then
        rfkill block wifi
		for mod in "${PREFERRED_WIFI_MODULES[@]}"; do
			[[ -z "$mod" ]] && continue
			modprobe -r "$mod" 2>/dev/null || true
		done

    fi
fi
EOF
	chmod +x /etc/systemd/system-sleep/wifi-manager-hook.sh
	
	Disable_Share
		
    dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_STATUS" --infobox "\n  $T_WIFI_DISABLED" 5 40 > "$CURR_TTY"
}

# -------------------------------------------------------
# Dependency check
# -------------------------------------------------------
Check_rfkill() {
    local REQUIRED_PACKAGES=("rfkill" "wpasupplicant" "network-manager")
    local MISSING_PACKAGES=()

    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            MISSING_PACKAGES+=("$pkg")
        fi
    done

    if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
    if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
            dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_INTERNET" --msgbox "\n $T_ACTIVE\n\n $T_PLEASE_CHECK" 9 60 > "$CURR_TTY"
            Exit_Menu
        fi
        dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_CHECK_DEP" --infobox "\n$T_PACKAGE ${MISSING_PACKAGES[*]}..." 5 60 > "$CURR_TTY"
         
        apt-get update -y >/dev/null 2>&1
        if apt-get install -y "${MISSING_PACKAGES[@]}" >/dev/null 2>&1; then
            dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_CHECK_DEP" --infobox "\n$T_COMPLETE ${MISSING_PACKAGES[*]}." 6 60 > "$CURR_TTY"
        else
            dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_CHECK_DEP" --msgbox "\n$T_ERR_TITLE: $T_PKG_ERR (${MISSING_PACKAGES[*]}). $T_TRY_AGAIN" 9 70 > "$CURR_TTY"
            Exit_Menu
        fi
    fi
}

# -------------------------------------------------------
# Exit the script
# -------------------------------------------------------
Exit_Menu() {
	trap - EXIT
    printf "\033[H\033[2J" > "$CURR_TTY"
    printf "\e[?25h" > "$CURR_TTY"
	Stop_GPTKeyb
    if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
        [ -n "$ORIGINAL_FONT" ] && setfont "$ORIGINAL_FONT"
    fi

    exit 0
}

# -------------------------------------------------------
# Connect to new network - dialog
# -------------------------------------------------------
Connect_New() {
	dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_AVAILABLE" --infobox "\n  $T_CONNECTING $1 ..." 5 45 > "$CURR_TTY"
	[[ "$MONITOR" == "ON" ]] && Stop_Connection_Monitor
	clist2=`nmcli -f ALL --mode tabular --terse --fields IN-USE,SSID,CHAN,SIGNAL,SECURITY dev wifi`
	SEC=$(echo "$clist2" | grep -F "$1" | grep -i -E "WPA|WEP")

	KEYBOARD="osk"
	if [[ ! -z "$SEC" ]]; then
		pgrep -f gptokeyb | xargs kill -9 2>/dev/null || true
        # -- get password from input ---
		PASS=$(osk "$T_PASSWORD ${1:0:15}" | tail -n 1)
		Start_GPTKeyb
        setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz
    fi
	
    dialog \
        --backtitle "$T_BACKTITLE2 $cur_ap" \
        --title "$T_AVAILABLE" \
        --infobox "\n $T_CONNECTING $1\n\n $T_WAIT" 7 40 > "$CURR_TTY"
		
 	# --- try to connect ---
	output=`nmcli con delete "$1"`
	if [[ -z "$SEC" ]]; then
        output=$(nmcli -w 10 device wifi connect "$1")
	else
		output=$(nmcli -w 10 device wifi connect "$1" password "$PASS")
	fi

	success=`echo "$output" | grep successfully`

	if [ -z "$success" ]; then
		output=" $T_FAIL_CONNECT"
		nmcli con down "$1" 2>/dev/null || true
		rm -f /etc/NetworkManager/system-connections/"$1".nmconnection
	else
		output=" $T_SUCCESS\n $1"
		iface=$(Get_Wifi_Interface)
		cur_ap=$(iw dev "$iface" info | grep ssid | cut -c 7-30)
	fi
	  
	dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_AVAILABLE" --infobox "\n$output" 6 40 > "$CURR_TTY"
	sleep 2
	if [[ "$success" ]] && [[ "$MONITOR" == "ON" ]]; then
		Start_Connection_Monitor
	fi
	return
}

# -------------------------------------------------------
# Connect to saved network - dialog
# -------------------------------------------------------
Connect_Saved() {
	Get_Current_AP

	dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_SAVED_TITLE" --infobox "\n  $T_CONNECTING $1 ..." 5 45 > "$CURR_TTY"
	[[ "$MONITOR" == "ON" ]] && Stop_Connection_Monitor

	[[ -n "$cur_ap" && "$cur_ap" != "$T_NONE" ]] && nmcli con down "$cur_ap" > /dev/null 2>&1 || true

	output=$(nmcli -w 10 con up "$1")

	success=`echo "$output" | grep successfully`

	if [ -z "$success" ]; then
		output=" $T_FAILED\n $1"
		nmcli con down "$1" 2>/dev/null || true
		cur_ap="$T_NONE"
	else
		output=" $T_SUCCESS\n $1"
		iface=$(Get_Wifi_Interface)
		cur_ap=$(iw dev "$iface" info | grep ssid | cut -c 7-30)
		[[ "$MONITOR" == "ON" ]] && Start_Connection_Monitor
	fi
	
	dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_SAVED_TITLE" --infobox "\n$output" 6 40 > "$CURR_TTY"
	sleep 1

	return
}

# -------------------------------------------------------
# Remove network - dialog
# -------------------------------------------------------
Remove_Network() {
    dialog \
        --clear \
        --backtitle "$T_BACKTITLE2 $cur_ap" \
        --title "$T_FORGET" --clear \
        --yesno "\n $T_REMOVE $1?" 6 45 > "$CURR_TTY" 2>&1
    if [[ $? != 0 ]]; then
        return
    fi
	
    dialog \
        --backtitle "$T_BACKTITLE2 $cur_ap" \
        --title "$T_FORGET" \
        --infobox "\n $T_WAIT" 5 40 > "$CURR_TTY"

    # --- if deleting the currently connected network, disconnect first ---
    if [[ "$1" == "$cur_ap" ]]; then
		[[ "$MONITOR" == "ON" ]] && Stop_Connection_Monitor
        nmcli con down "$1" > /dev/null 2>&1 || true
		Disable_Share
	fi
	
    nmcli connection delete "$1" >/dev/null 2>&1 || true
    rm -f "/etc/NetworkManager/system-connections/$1.nmconnection"
    Get_Current_AP
	return
}

# -------------------------------------------------------
# Display available networks - dialog
# -------------------------------------------------------
Add_Network() {
	dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_AVAILABLE" --infobox "\n  $T_SCAN" 5 40 > "$CURR_TTY"
	clist=`nmcli -f ALL --mode tabular --terse --fields IN-USE,SSID,CHAN,SIGNAL,SECURITY dev wifi`
	sleep 0.5
	if [ -z "$clist" ]; then
		clist=`nmcli -f ALL --mode tabular --terse --fields IN-USE,SSID,CHAN,SIGNAL,SECURITY dev wifi`
	fi

	# --- set colon as the delimiter ---
	unset coptions
	while IFS= read -r clist; do
	# --- read the split words into an array based on colon delimiter ---
	IFS=':' read -a strarr <<< "$clist"
	
    INUSE=`printf '%-5s' "${strarr[0]}"`
    SSID="${strarr[1]}"
    CHAN=`printf '%-5s' "${strarr[2]}"`
    SIGNAL=`printf '%-5s' "${strarr[3]}%"`
    SECURITY="${strarr[4]}"
	
	[[ -z "$SSID" ]] && continue    # skip empty SSIDs

    coptions+=("$SSID" "$INUSE $CHAN $SIGNAL $SECURITY")
	done <<< "$clist"

	while true; do
		cselection=(dialog \
		--backtitle "$T_BACKTITLE2 $cur_ap" \
		--title "$T_AVAILABLE" \
		--no-collapse \
		--clear \
		--cancel-label "$T_BACK" \
		--menu "" 14 50 8)

		cchoices=$("${cselection[@]}" "${coptions[@]}" 2>&1 > "$CURR_TTY")
		if [[ $? != 0 || -z "$cchoices" ]]; then
			Main_Menu
			return
		fi

		    case "$cchoices" in
			*) Connect_New "$cchoices" ;;
		    esac
	done
}

# -------------------------------------------------------
# Display saved networks - dialog
# -------------------------------------------------------
Saved_Networks() {
	declare aoptions=()
	while IFS= read -r -d $'\n' ssid; do
        aoptions+=("$ssid" ".")
	done < <(ls -1 /etc/NetworkManager/system-connections/ | rev | cut -c 14- | rev | sed -e 's/$//')
	
	# --- no saved networks ---
	if [[ ${#aoptions[@]} -eq 0 ]]; then
		dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_SAVED_TITLE" --infobox "\n  $T_NO_SAVED" 5 40 > "$CURR_TTY"
		sleep 1
		Main_Menu
		return
	fi
	
	while true; do
        aselection=(dialog \
       	--backtitle "$T_BACKTITLE2 $cur_ap" \
   	    --title "$T_SAVED_TITLE" \
    	--clear \
 	    --cancel-label "$T_BACK" \
        --menu "" 10 40 15)

    achoice=$("${aselection[@]}" "${aoptions[@]}" 2>&1 > "$CURR_TTY")
	if [[ $? != 0 || -z "$achoice" ]]; then
		Main_Menu
		return
	fi

    Connect_Saved "$achoice"
    done  
}

# -------------------------------------------------------
# Forget network - dialog
# -------------------------------------------------------
Forget_Network() {
	Get_Current_AP
	
	while true; do
		declare deloptions=()
		while IFS= read -r -d $'\n' ssid; do
			deloptions+=("$ssid" ".")
		done < <(ls -1 /etc/NetworkManager/system-connections/ | rev | cut -c 14- | rev | sed -e 's/$//')
		
		# --- no saved networks ---
		if [[ ${#deloptions[@]} -eq 0 ]]; then
			dialog --backtitle "$T_BACKTITLE2 $cur_ap" --title "$T_FORGET" --infobox "\n  $T_NO_SAVED" 5 40 > "$CURR_TTY"
			sleep 1
			Main_Menu
			return
		fi
			
		delselection=(dialog \
		--backtitle "$T_BACKTITLE2 $cur_ap" \
		--title "$T_FORGET" \
		--no-collapse \
		--clear \
		--cancel-label "$T_BACK" \
		--menu "" 10 40 15)

		delchoice=$("${delselection[@]}" "${deloptions[@]}" 2>&1 > "$CURR_TTY")
		if [[ $? != 0 || -z "$delchoice" ]]; then
			Main_Menu
			return
		fi

		Remove_Network "$delchoice"
	done  
}

# -------------------------------------------------------
# Display connected network information - dialog
# -------------------------------------------------------
Network_Info() {
	Get_Current_AP
	gateway=$(ip route get 1 2>/dev/null | awk '{print $3; exit}')
	[[ -z "$gateway" ]] && gateway=""
	iface=$(Get_Wifi_Interface)
	if [[ -z "$iface" ]]; then
		currentip=""
		currentssid=""
	else
		currentip=$(ip -f inet addr show "$iface" 2>/dev/null | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
		currentssid=$(iw dev "$iface" info 2>/dev/null | grep ssid | cut -c 7-30)
	fi

	if [[ -z $currentssid ]]; then
		currentssid=$(nmcli -t -f name,device connection show --active | grep "$iface" | cut -d\: -f1)
	fi
	
	if [[ -z "$iface" ]]; then
		dns_list=""
	else
		dns_list=$(timeout 3 nmcli -g IP4.DNS dev show "$iface" 2>/dev/null)
	fi
		currentdns1=$(echo "$dns_list" | cut -d'|' -f1 | xargs)
		currentdns2=$(echo "$dns_list" | cut -d'|' -f2 | xargs)

	dialog \
		--backtitle "$T_BACKTITLE2 $cur_ap" \
		--title "$T_INFO" \
		--clear \
		--no-collapse \
		--ok-label "$T_BACK" \
		--msgbox "\n  SSID: $cur_ap\n  IP: $currentip\n  Gateway: $gateway\n  DNS1: $currentdns1\n  DNS2: $currentdns2" 11 36 2>&1 > "$CURR_TTY"
	if [[ $? != 0 ]]; then
		Main_Menu
		return
	fi
}

# -------------------------------------------------------
# Check state of remote access, set flag
# -------------------------------------------------------
Check_Remote_Status() {
    if timeout 3 systemctl is-active --quiet smbd 2>/dev/null ||
       # timeout 3 systemctl is-active --quiet ssh.service 2>/dev/null ||
       pgrep -f filebrowser >/dev/null 2>/dev/null
    then
        REMOTE_ACTIVE=1
    else
        REMOTE_ACTIVE=0
    fi
}

# -------------------------------------------------------
# Turn on remote access - dialog
# -------------------------------------------------------
Enable_Share() {
	timedatectl set-ntp 1 >/dev/null 2>&1 || true
	systemctl start smbd 2>/dev/null || true
	systemctl start nmbd 2>/dev/null || true
	systemctl start ssh.service 2>/dev/null || true
	filebrowser -a 0.0.0.0 -p 80 -d /home/ark/.config/filebrowser.db -r / > /dev/null 2>&1 &
	
	# --- update share state flag ---
	REMOTE_ACTIVE=1
}

# -------------------------------------------------------
# Turn off remote access - dialog
# -------------------------------------------------------
Disable_Share() {
	timedatectl set-ntp 0 >/dev/null 2>&1 || true
	systemctl stop smbd 2>/dev/null || true
	systemctl stop nmbd 2>/dev/null || true
	systemctl stop ssh.service 2>/dev/null || true
	pkill -f filebrowser > /dev/null 2>&1 || true
	
	# --- update share state flag ---
	REMOTE_ACTIVE=0
}

# -------------------------------------------------------
# Turn remote access on or off
# -------------------------------------------------------
Toggle_Remote() {
	Check_Remote_Status
	if [ "${REMOTE_ACTIVE:-0}" -eq 1 ]; then
		Get_Current_AP
		dialog \
			--backtitle "$T_BACKTITLE2 $cur_ap" \
			--title "$T_REMOTE" \
			--infobox "\n  $T_STOP_REMOTE\n\n  $T_WAIT" 7 40 > "$CURR_TTY"
		Disable_Share
		dialog \
			--backtitle "$T_BACKTITLE2 $cur_ap" \
			--title "$T_REMOTE" \
			--infobox "\n  $T_REMOTE_DISABLED" 5 40 > "$CURR_TTY"
			
		sleep 1
	else
		Get_Current_AP
		dialog \
			--backtitle "$T_BACKTITLE2 $cur_ap" \
			--title "$T_REMOTE" \
			--infobox "\n  $T_START_REMOTE\n\n  $T_WAIT" 7 40 > "$CURR_TTY"

		gateway=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')
		if [[ -z "$gateway" ]]; then
			dialog \
				--backtitle "$T_BACKTITLE2 $cur_ap" \
				--title "$T_REMOTE" \
				--msgbox "\n  $T_INTERNET\n\n  $T_TRY_AGAIN" 8 45 > "$CURR_TTY"
			return
		fi
		Enable_Share
		CURRENT_IP=$(ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
		dialog \
			--backtitle "$T_BACKTITLE2 $cur_ap" \
			--title "$T_REMOTE" \
			--ok-label "$T_BACK" \
			--msgbox "\n  $T_REMOTE_RUNNING\n\n  $T_IP_ADDRESS\n\n           $CURRENT_IP" 10 40 > "$CURR_TTY"
	fi
}

# -------------------------------------------------------
# Turn Wifi on or off, keep track with state file
# -------------------------------------------------------
Toggle_Wifi() {
	local state="UNKNOWN"

	# --- use state file if available, otherwise fall back to detection ---
	if [ -f /tmp/wifi_manager_state ]; then
		state=$(cat /tmp/wifi_manager_state)
	elif echo "$(Get_Wifi_Status)" | grep -qi "ON"; then
		state="ON"
	else
		state="OFF"
	fi

	if [ "$state" == "ON" ]; then
		Disable_Wifi
	else
		Enable_Wifi
		sleep 0.5
		Get_Current_AP
	fi
}

# -------------------------------------------------------
# Main Menu dialog
# -------------------------------------------------------
Main_Menu() {
    IFS="$old_ifs"
	Check_Remote_Status
	
    while true; do
		local WIFI_SHORT
		local CUR_AP
		
		# --- keep gptokeyb alive ---
		if [[ -z $(pgrep -f gptokeyb) ]]; then
			Start_GPTKeyb
		fi
		
		# --- refresh wifi state ---
		if [ -f /tmp/wifi_manager_state ]; then
            WIFI_SHORT=$(cat /tmp/wifi_manager_state)
        elif echo "$(Get_Wifi_Status)" | grep -qi "ON"; then
            WIFI_SHORT="ON"
        else
            WIFI_SHORT="OFF"
        fi
        	
		if [ "$WIFI_SHORT" = "ON" ]; then
			Get_Current_AP
			CUR_AP="\Z4$cur_ap\Zn"
			if [ "${REMOTE_ACTIVE:-0}" -eq 1 ]; then
				WIFI_SHORT="\Z2$T_ON, $T_SHARING\Zn"
			else
				WIFI_SHORT="\Z2$T_ON\Zn"
			fi
			TOGGLE_LABEL="$T_DISABLE Wi-Fi"
		else
			CUR_AP="$T_NONE"
			WIFI_SHORT="\Z1$T_OFF\Zn"
			TOGGLE_LABEL="$T_ENABLE Wi-Fi"
		fi
		
		if [ "${REMOTE_ACTIVE:-0}" -eq 1 ]; then
			TOGGLE_REMOTE="$T_DISABLE $T_REMOTE"
		else
			TOGGLE_REMOTE="$T_ENABLE $T_REMOTE"
		fi

		mainoptions=( 1 "$TOGGLE_LABEL" 2 "$T_ADD_NEW" 3 "$T_SAVED_TITLE" 4 "$T_FORGET" 5 "$TOGGLE_REMOTE" 6 "$T_INFO" )

		mainselection=(dialog \
			--colors \
			--backtitle "$T_BACKTITLE" \
			--title "$T_MAIN_TITLE" \
			--no-collapse \
			--clear \
			--cancel-label "$T_EXIT" \
			--menu "Wi-Fi $T_STATUS: $WIFI_SHORT\n$T_CONN_TO: $CUR_AP" 14 45 6)

		mainchoices=$("${mainselection[@]}" "${mainoptions[@]}" 2>&1 > "$CURR_TTY")
			if [[ $? != 0 || -z "$mainchoices" ]]; then
				Exit_Menu
			fi

			case $mainchoices in
				1) Toggle_Wifi ;;
				2) Add_Network ;;
				3) Saved_Networks ;;
				4) Forget_Network ;;
				5) Toggle_Remote ;;
				6) Network_Info ;;
			esac
	done
}

# -------------------------------------------------------
# Gamepad Setup
# -------------------------------------------------------
export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
sudo chmod 666 /dev/uinput
Start_GPTKeyb

# -------------------------------------------------------
# Set initial wifi_manager_state
# -------------------------------------------------------
if echo "$(Get_Wifi_Status)" | grep -qi "ON"; then
	echo "ON" > /tmp/wifi_manager_state
else
	echo "OFF" > /tmp/wifi_manager_state
fi

# ---------------------------------------------------------
# Main Execution
# ---------------------------------------------------------
printf "\033[H\033[2J" > "$CURR_TTY"
dialog --clear
trap Exit_Menu EXIT

[[ "$MONITOR" != "ON" ]] && Stop_Connection_Monitor
Update_Preferred_Modules
Check_rfkill
Check_Remote_Status

iface_check=""
iface_check=$(ip link show | awk '/wlan[0-9]+:/ {gsub(":", ""); print $2; exit}' || true)
if [[ -n "$iface_check" ]]; then
	iwconfig "$iface_check" power off 2>/dev/null || true
	[[ "$MONITOR" == "ON" ]] && Start_Connection_Monitor
fi

# --- Creates a persistent NM config to disable wifi power saving ---
# --- Remove /etc/NetworkManager/conf.d/wifi-powersave-off.conf to revert ---
if [ ! -f /etc/NetworkManager/conf.d/wifi-powersave-off.conf ]; then
    cat > /etc/NetworkManager/conf.d/wifi-powersave-off.conf << 'EOF'
[connection]
wifi.powersave = 2
EOF
    nmcli general reload 2>/dev/null || true
fi
			
Main_Menu