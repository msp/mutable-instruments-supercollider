#!/usr/bin/env bash
#
# netmode — switch the Mac's Wi-Fi between show-control static and normal DHCP
#
#   netmode show     pin to 192.168.8.10 for the msp network
#   netmode normal   back to DHCP for any other Wi-Fi
#   netmode          print current state
#
set -euo pipefail

SERVICE="Wi-Fi"
SSID="msp"
IP="192.168.8.10"
MASK="255.255.255.0"
ROUTER="192.168.8.1"
DNS="192.168.8.1"

WIFI_DEV="$(networksetup -listallhardwareports \
  | awk -v s="$SERVICE" '$0 == "Hardware Port: "s {getline; print $2}')"

if [[ -z "$WIFI_DEV" ]]; then
  echo "netmode: couldn't find a '$SERVICE' service — check networksetup -listallnetworkservices" >&2
  exit 1
fi

status() {
  local mode ip ssid dns
  mode="$(networksetup -getinfo "$SERVICE" | head -1)"
  ip="$(ipconfig getifaddr "$WIFI_DEV" 2>/dev/null || echo "—")"
  ssid="$(networksetup -getairportnetwork "$WIFI_DEV" 2>/dev/null \
    | sed 's/^Current Wi-Fi Network: //' || echo "—")"
  dns="$(networksetup -getdnsservers "$SERVICE" 2>/dev/null | tr '\n' ' ')"
  [[ "$dns" == *"aren't any"* ]] && dns="—"

  printf '\n'
  printf '  %-7s %s\n' "mode"  "$mode"
  printf '  %-7s %s\n' "ssid"  "$ssid"
  printf '  %-7s %s\n' "ip"    "$ip"
  printf '  %-7s %s\n' "dns"   "$dns"
  printf '\n'
}

case "${1:-status}" in
  show)
    sudo networksetup -setmanual    "$SERVICE" "$IP" "$MASK" "$ROUTER"
    sudo networksetup -setdnsservers "$SERVICE" "$DNS"
    # join msp if it's a remembered network; harmless if already on it
    networksetup -setairportnetwork "$WIFI_DEV" "$SSID" >/dev/null 2>&1 || true
    echo "→ show mode"
    ;;
  normal)
    sudo networksetup -setdhcp      "$SERVICE"
    sudo networksetup -setdnsservers "$SERVICE" empty
    echo "→ normal mode"
    ;;
  status|"")
    ;;
  *)
    echo "usage: netmode [show|normal|status]" >&2
    exit 1
    ;;
esac

sleep 1
status
