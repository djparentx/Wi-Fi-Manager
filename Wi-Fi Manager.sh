#!/bin/bash

# =======================================
# Wi-Fi Manager 3.5.4 for ArkOS and dArkOS
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

MONITOR=ON			# ON for connection healing
POWERSAVE_OFF=ON	# ON for connection stability (OFF for R36XX)
WIFI_LOG=OFF		# ON for logging

# -------------------------------------------------------
# Root privileges check
# -------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

# -------------------------------------------------------
# Creates a persistent NM config to disable wifi power saving
# Set POWERSAVE_OFF=OFF to revert
# -------------------------------------------------------
if grep -q "r36xx" /proc/device-tree/compatible; then
    POWERSAVE_OFF=OFF
fi

if [[ "$POWERSAVE_OFF" == "ON" ]]; then
	if [ ! -f /etc/NetworkManager/conf.d/wifi-powersave-off.conf ]; then
		cat > /etc/NetworkManager/conf.d/wifi-powersave-off.conf << 'EOF'
[connection]
wifi.powersave = 2
EOF
		nmcli general reload 2>/dev/null || true
	fi
else
	rm -f /etc/NetworkManager/conf.d/wifi-powersave-off.conf
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
TMP_KEYS="/tmp/keys.gptk.$$"
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
T_DRIVER_TITLE="[ DRIVERS MISSING ]"
T_DRIVER_MSG="WiFi drivers missing.\n\nInstall RTL8188EUS WiFi driver?"
T_DRIVER_INST="[ DRIVERS INSTALLED ]"
T_DRIVER_SUCC="RTL8188EUS WiFi driver installed successfully."

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
T_DRIVER_TITLE="[ PILOTES MANQUANTS ]"
T_DRIVER_MSG="Pilotes WiFi manquants.\n\nInstaller le pilote WiFi RTL8188EUS ?"
T_DRIVER_INST="[ PILOTES INSTALLES ]"
T_DRIVER_SUCC="Pilote WiFi RTL8188EUS installe avec succes."

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
T_DRIVER_TITLE="[ CONTROLADORES FALTANTES ]"
T_DRIVER_MSG="Faltan controladores WiFi.\n\nInstalar el controlador WiFi RTL8188EUS?"
T_DRIVER_INST="[ CONTROLADORES INSTALADOS ]"
T_DRIVER_SUCC="Controlador WiFi RTL8188EUS instalado correctamente."

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
T_DRIVER_TITLE="[ DRIVERS EM FALTA ]"
T_DRIVER_MSG="Drivers WiFi em falta.\n\nInstalar o driver WiFi RTL8188EUS?"
T_DRIVER_INST="[ DRIVERS INSTALADOS ]"
T_DRIVER_SUCC="Driver WiFi RTL8188EUS instalado com sucesso."

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
T_DRIVER_TITLE="[ DRIVER MANCANTI ]"
T_DRIVER_MSG="Driver WiFi mancanti.\n\nInstallare il driver WiFi RTL8188EUS?"
T_DRIVER_INST="[ DRIVER INSTALLATI ]"
T_DRIVER_SUCC="Driver WiFi RTL8188EUS installato con successo."

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
T_DRIVER_TITLE="[ TREIBER FEHLEN ]"
T_DRIVER_MSG="WiFi Treiber fehlen.\n\nRTL8188EUS WiFi Treiber installieren?"
T_DRIVER_INST="[ TREIBER INSTALLIERT ]"
T_DRIVER_SUCC="RTL8188EUS WiFi Treiber erfolgreich installiert."

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
T_DRIVER_TITLE="[ BRAKUJACE STEROWNIKI ]"
T_DRIVER_MSG="Brakuja sterowniki WiFi.\n\nZainstalowac sterownik WiFi RTL8188EUS?"
T_DRIVER_INST="[ STEROWNIKI ZAINSTALOWANE ]"
T_DRIVER_SUCC="Sterownik WiFi RTL8188EUS zainstalowany pomyslnie."
fi

# -------------------------------------------------------
# Start gamepad input
# -------------------------------------------------------
Start_GPTKeyb() {
    pkill -9 -f gptokeyb 2>/dev/null || true
    if [ -n "${GPTOKEYB_PID:-}" ]; then
        kill "$GPTOKEYB_PID" 2>/dev/null
    fi
    sleep 0.1
	/opt/inttools/gptokeyb -1 "$0" -c "$TMP_KEYS" > /dev/null 2>&1 &
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

Cleanup() {
    rm -f "$TMP_KEYS"
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
# Install rtl8188eufw.bin if needed
# -------------------------------------------------------
RTL8188_B64="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"

InstallWiFiDrivers() {
    mkdir -p /lib/firmware/rtlwifi
    printf '%s' "$RTL8188_B64" | base64 -d > /lib/firmware/rtlwifi/rtl8188eufw.bin
    chmod 644 /lib/firmware/rtlwifi/rtl8188eufw.bin
	
	modprobe -r r8188eu 2>/dev/null
    modprobe r8188eu 2>/dev/null
    
	dialog --backtitle "$BACKTITLE" \
           --title "$T_DRIVER_INST" \
           --msgbox "$T_DRIVER_SUCC" 7 45 > "$CURR_TTY"
}

# -------------------------------------------------------
# Gamepad Setup
# -------------------------------------------------------
export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
chmod 666 /dev/uinput
cp /opt/inttools/keys.gptk "$TMP_KEYS"
if grep -q '^b = backspace' "$TMP_KEYS"; then
    sed -i 's/^b = .*/b = esc/' "$TMP_KEYS"
    sed -i 's/^a = .*/a = enter/' "$TMP_KEYS"
fi
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
trap 'Stop_GPTKeyb; Cleanup; Exit_Menu' EXIT

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

if ! { { modinfo r8188eu &>/dev/null && [[ -f /lib/firmware/rtlwifi/rtl8188eufw.bin ]]; } || \
	   { modinfo mt7601u &>/dev/null && { [[ -f /lib/firmware/mt7601u.bin ]] || [[ -f /lib/firmware/mediatek/mt7601u.bin ]]; }; }; }; then

	dialog --backtitle "$T_BACKTITLE" \
		   --title "$T_DRIVER_TITLE" \
		   --yesno "$T_DRIVER_MSG" 8 50 > "$CURR_TTY"
	if [ $? -ne 0 ]; then
        Exit_Menu
    else
        InstallWiFiDrivers
    fi
fi
		
Main_Menu