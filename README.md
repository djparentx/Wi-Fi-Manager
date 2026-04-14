Wi-Fi Manager for ArkOS / dArkOS

v3.5.2 by djparent Based on Wi-Fi by Kris Henriksen. Additional code from Wifi-Toggle v3.6 and Bluetooth Manager for dArkOS by Jason3x.
What's New vs. the Original:

Multilingual Support

Automatically detects the language set in EmulationStation and displays all menus and messages in English, French, Spanish, Portuguese, Italian, German, or Polish.
USB OTG Wi-Fi Adapter Support

Handles the full lifecycle of USB Wi-Fi adapters — module detection, loading/unloading, USB bus ejection, and re-enumeration via the dwc2 driver. Installs a persistent systemd service (wifi-usb-old-scheme.service) to ensure proper USB enumeration on every boot.
Wi-Fi State Persistence Across Sleep/Wake

Creates a systemd sleep hook (/etc/systemd/system-sleep/wifi-manager-hook.sh) when Wi-Fi is disabled, so it stays off across suspend/resume cycles. The hook is removed when Wi-Fi is re-enabled.
Power Saving Disabled

On first run, creates /etc/NetworkManager/conf.d/wifi-powersave-off.conf to permanently disable NetworkManager's Wi-Fi power saving. This significantly reduces dropped connections.

    To revert: sudo rm /etc/NetworkManager/conf.d/wifi-powersave-off.conf

Wi-Fi State File

Uses /tmp/wifi_manager_state to track whether Wi-Fi is on or off. This is necessary because physical USB ejection makes hardware detection unreliable as a source of truth.
Background Connection Monitor

An optional background process (MONITOR=ON) that watches for disconnections and automatically reconnects within ~15 seconds without user intervention. Logs activity when WIFI_LOG=ON.
Remote Access Toggle

Enables/disables Samba (smbd/nmbd), SSH, and FileBrowser as a group. Displays your current IP address when enabled. Remote access is automatically shut down when Wi-Fi is disabled or a network is forgotten.
Improved Connection Handling

    nmcli connection attempts use -w 10 to time out after 10 seconds instead of hanging for up to 30 seconds on failure
    On connection failure, NetworkManager is explicitly told to release the phantom connection immediately rather than waiting for it to time out on its own
    Network scan retries wait 0.5 seconds before the second attempt so the retry is actually meaningful

Dependency Check

Automatically checks for and installs rfkill, wpasupplicant, and network-manager if missing, with clear error messaging if an internet connection isn't available.
Gamepad Input Management

Manages gptokeyb lifecycle carefully — kills stale instances before launching, restores it after the on-screen keyboard is used, and keeps it alive across menu loops.
Clean Exit Handling

Restores the original console font on exit (except on Odroid-based devices where font restoration causes issues), kills gptokeyb cleanly, and uses a trap to ensure cleanup runs even on unexpected exits.
Configuration

At the top of the script:
bash

WIFI_LOG=OFF    # Set to ON to enable connection monitor logging
MONITOR=ON      # Set to ON to enable automatic reconnection

Requirements

    ArkOS or dArkOS
    rfkill, wpasupplicant, network-manager (auto-installed if missing)
    gptokeyb and osk from /opt/inttools/
    dialog

Credits

    Original Wi-Fi script by Kris Henriksen
    Wifi-Toggle v3.6 and Bluetooth Manager for dArkOS by Jason3x
