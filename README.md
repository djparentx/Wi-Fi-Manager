# R36S Wi-Fi Manager (ArkOS / dArkOS)

v3.5.2 by djparent  
Based on Wifi script by Kris Henriksen, with additional code from Wifi-Toggle v3.6 and Bluetooth Manager for dArkOS by Jason3x.

---

## Overview

An advanced Wi-Fi management tool for the R36S that improves reliability, adds automation, and provides a controller-friendly interface with full system integration.

---

## Features

- Multi-language support (EN, FR, ES, PT, IT, DE, PL)
- Full Wi-Fi control (enable / disable)
- USB OTG Wi-Fi adapter support with automatic handling
- Persistent Wi-Fi state across sleep / wake cycles
- Automatic reconnection monitor (optional)
- Remote access toggle (SSH, Samba, FileBrowser)
- Improved connection handling and faster timeouts
- Automatic dependency detection and installation
- Clean UI designed for handheld use
- Safe startup and exit handling

---

## What’s New vs Original

- Automatic language detection from EmulationStation
- Full USB Wi-Fi lifecycle management (load, unload, re-enumerate)
- Persistent systemd service for USB Wi-Fi initialization
- Sleep hook to preserve Wi-Fi state across suspend/resume
- Disabled NetworkManager power saving for stability
- State tracking via `/tmp/wifi_manager_state`
- Background auto-reconnect system
- Integrated remote access controls with IP display
- Faster and more reliable connection attempts
- Improved input handling with gptokeyb management
- Clean exit handling with proper system restoration

---

## USB Wi-Fi Support

Handles USB OTG adapters completely:

- Detects and loads correct kernel modules
- Safely unloads and ejects USB devices
- Reinitializes via `dwc2` driver
- Installs persistent systemd service:

  /etc/systemd/system/wifi-usb-old-scheme.service

Ensures proper adapter detection on every boot.

---

## Wi-Fi State Persistence

- Tracks Wi-Fi state using:

  /tmp/wifi_manager_state

- When Wi-Fi is disabled:
  - Creates sleep hook:

    /etc/systemd/system-sleep/wifi-manager-hook.sh

  - Keeps Wi-Fi OFF after suspend/resume

- Hook is automatically removed when Wi-Fi is re-enabled

---

## Power Saving Fix

Disables NetworkManager Wi-Fi power saving to prevent drops:

- Created on first run:

  /etc/NetworkManager/conf.d/wifi-powersave-off.conf

- Improves connection stability significantly

To revert:

  sudo rm /etc/NetworkManager/conf.d/wifi-powersave-off.conf

---

## Background Monitor

Optional automatic reconnection system:

- Enabled with:

  MONITOR=ON

- Detects dropped connections
- Reconnects automatically within ~15 seconds
- Logging available with:

  WIFI_LOG=ON

---

## Remote Access

Toggle remote services as a group:

- SSH
- Samba (smbd / nmbd)
- FileBrowser

Features:

- Displays current IP address when enabled
- Automatically disables services when:
  - Wi-Fi is turned off
  - Network is forgotten

---

## Connection Improvements

- Uses `nmcli -w 10` to prevent long hangs
- Forces immediate cleanup on failed connections
- Adds retry delay for more reliable scans
- Reduces overall connection instability

---

## Dependency Management

Automatically checks and installs:

- rfkill
- wpasupplicant
- network-manager

If missing:

- Requires internet connection
- Displays clear error messages if unavailable

---

## Input Handling

- Manages gptokeyb lifecycle cleanly
- Prevents duplicate or stuck instances
- Restores controls after on-screen keyboard use
- Maintains stable input across menu loops

---

## Exit Handling

- Restores original console font
- Kills gptokeyb cleanly
- Uses trap to ensure cleanup on exit or crash

---

## Configuration

Inside the script:

WIFI_LOG=OFF    # Enable logging (ON/OFF)  
MONITOR=ON      # Enable auto-reconnect (ON/OFF)

---

## Requirements

- R36S running ArkOS or dArkOS
- Internet connection (for first run if dependencies missing)
- Root privileges

---

## Notes

- Designed specifically for R36S hardware
- Handles unreliable USB Wi-Fi behavior common on these devices
- Safe to re-run without breaking existing configuration

---

## Credits

- Original Wi-Fi script by Kris Henriksen  
- Wifi-Toggle v3.6 and Bluetooth Manager contributions by Jason3x  
- Enhancements and integration by djparent  

---
